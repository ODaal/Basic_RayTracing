from pynq import Overlay, MMIO, allocate
from pynq.lib import DebugBridge
import numpy as np, time

ol = Overlay("/home/xilinx/RayTracer_wrapper.xsa"); ol.download()

bridge = DebugBridge(ol.ip_dict['debug_bridge_0'])
bridge.start_xvc_server(bufferLen=4096, serverAddress="0.0.0.0",serverPort=2542, reconnect=True, verbose=True)

vdma = MMIO(ol.ip_dict['axi_vdma_0']['phys_addr'],
            ol.ip_dict['axi_vdma_0'].get('addr_range', 0x1000))

# ---------------- The following was coded using AI ---------------------------------------------------------

# ---- AXI VDMA registers (offsets) ----
MM2S_DMACR,MM2S_DMASR,MM2S_VSIZE,MM2S_HSIZE,MM2S_STRIDE,MM2S_SA0 = 0x00,0x04,0x50,0x54,0x58,0x5C
S2MM_DMACR,S2MM_DMASR,S2MM_VSIZE,S2MM_HSIZE,S2MM_STRIDE,S2MM_SA0 = 0x30,0x34,0xA0,0xA4,0xA8,0xAC
S2MM_HSIZE_STAT, S2MM_VSIZE_STAT = 0xF0, 0xF4
S2MM_IRQ_FRAME_CNT = 0xE8  # number of frames before IOC when FrameCntEn=1

# ---- control/status bits ----
DMACR_RS        = 1<<0
DMACR_RESET     = 1<<2
DMACR_FRMCNT_EN = 1<<4          # enable frame counter mode (one-shot when IRQ_FRAME_CNT=1)
DMACR_IOC_IRQEN = 1<<12         # enable frame-done interrupt (IOC)
DMACR_ERR_IRQEN = 1<<14

VDMASR_Halted   = 1<<0
VDMASR_Idle     = 1<<1
VDMASR_IntErr   = 1<<4
VDMASR_SlvErr   = 1<<5
VDMASR_DecErr   = 1<<6
VDMASR_SOF_E    = 1<<7
VDMASR_EOL_E    = 1<<8
VDMASR_SOF_L    = 1<<11
VDMASR_FrmIrq   = 1<<12
VDMASR_ErrIrq   = 1<<14
ERR_MASK = (VDMASR_IntErr|VDMASR_SlvErr|VDMASR_DecErr|VDMASR_SOF_E|VDMASR_EOL_E|VDMASR_SOF_L|VDMASR_ErrIrq)

# ---- geometry ----
W, H, BPP = 640, 480, 3
STRIDE = W*BPP                  # 1920 bytes/line
HSIZE  = STRIDE                 # 1920
VSIZE  = H                      # 480

# ---- buffer ----
fb = allocate(shape=(VSIZE, STRIDE), dtype=np.uint8); fb[:] = 0
phys = fb.physical_address

def dump_s2mm(tag):
    sr = vdma.read(S2MM_DMASR)
    print(f"{tag}: DMASR=0x{sr:08x}  HSIZE_STAT={vdma.read(S2MM_HSIZE_STAT)}  VSIZE_STAT={vdma.read(S2MM_VSIZE_STAT)}")

# ---------------- Capture ONE frame (S2MM) ----------------
# reset & clear
vdma.write(S2MM_DMACR, DMACR_RESET)
t0=time.time()
while vdma.read(S2MM_DMACR) & DMACR_RESET:
    if time.time()-t0 > 0.2: raise RuntimeError("S2MM reset stuck")
vdma.write(S2MM_DMASR, ERR_MASK | VDMASR_FrmIrq)  # W1C

# program addresses/sizes
vdma.write(S2MM_SA0,    phys)
vdma.write(S2MM_STRIDE, STRIDE)
vdma.write(S2MM_HSIZE,  HSIZE)

# --- Enable "capture N frames then halt": N = 1 ---
vdma.write(S2MM_IRQ_FRAME_CNT, 1)                          # IRQ after 1 frame
vdma.write(S2MM_DMACR, DMACR_RS | DMACR_FRMCNT_EN |
                         DMACR_IOC_IRQEN | DMACR_ERR_IRQEN)

print("S2MM DMACR=0x%08x" % vdma.read(S2MM_DMACR))
sr = vdma.read(S2MM_DMASR)
print("S2MM DMASR=0x%08x (Halted=%d Idle=%d)" % (sr, sr&1!=0, sr>>1&1))
print("STRIDE=%d HSIZE=%d VSIZE=%d" % (vdma.read(S2MM_STRIDE),
                                      vdma.read(S2MM_HSIZE),
                                      vdma.read(S2MM_VSIZE)))
print("HSIZE_STAT=%d VSIZE_STAT=%d" % (vdma.read(0xF0), vdma.read(0xF4)))


# arm by writing VSIZE last (starts when next SOF arrives)
vdma.write(S2MM_VSIZE,  VSIZE)

# wait for completion / error
t0=time.time()
while True:
    sr = vdma.read(S2MM_DMASR)
    if sr & ERR_MASK:
        dump_s2mm("S2MM ERR")
        vdma.write(S2MM_DMASR, sr & (ERR_MASK|VDMASR_FrmIrq))
        print("S2MM DMACR=0x%08x" % vdma.read(S2MM_DMACR))
        sr = vdma.read(S2MM_DMASR)
        print("S2MM DMASR=0x%08x (Halted=%d Idle=%d)" % (sr, sr&1!=0, sr>>1&1))
        print("STRIDE=%d HSIZE=%d VSIZE=%d" % (vdma.read(S2MM_STRIDE),
        vdma.read(S2MM_HSIZE),
        vdma.read(S2MM_VSIZE)))
        print("HSIZE_STAT=%d VSIZE_STAT=%d" % (vdma.read(0xF0), vdma.read(0xF4)))

        raise RuntimeError(f"S2MM error: DMASR=0x{sr:08x}")
    if sr & VDMASR_FrmIrq:
        vdma.write(S2MM_DMASR, VDMASR_FrmIrq)              # ack
        break
    if time.time()-t0 > 2.0:
        dump_s2mm("S2MM TIMEOUT")
        raise TimeoutError(f"S2MM timeout: DMASR=0x{sr:08x}")

dump_s2mm("S2MM DONE (one-shot)")

# ---------------- Loop to HDMI (MM2S) ----------------
vdma.write(MM2S_DMASR, ERR_MASK | VDMASR_FrmIrq)           # clear
vdma.write(MM2S_SA0,    phys)
vdma.write(MM2S_STRIDE, STRIDE)
vdma.write(MM2S_HSIZE,  HSIZE)
vdma.write(MM2S_VSIZE,  VSIZE)
vdma.write(MM2S_DMACR,  DMACR_RS | DMACR_IOC_IRQEN | DMACR_ERR_IRQEN)

print("Captured one frame to DDR and started continuous playback to HDMI.")


