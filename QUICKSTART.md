# ?? Quick Start Guide - ROCm Windows 11 Installer

## TL;DR - Get Running in 5 Minutes

### Step 1: Prerequisites Check (1 minute)
? Windows 11 (Build 22000+)  
? AMD Radeon RX 7000 Series GPU  
? Administrator access  
? Internet connection  

### Step 2: Clone & Setup (2 minutes)
```bash
git clone https://github.com/OCNGill/ROCm_Installer_Win11.git
cd ROCm_Installer_Win11
conda env create -f environment.yml
conda activate ROCm_installer_env
```

### Step 3: Launch Installer (30 seconds)
```bash
streamlit run src/gui/streamlit_app.py
```

### Step 4: Follow GUI (1-2 minutes of clicking)
1. **Compatibility Tab** ? Click "Run Compatibility Check"
2. **Installation Tab** ? Click through each step:
   - WSL2 Setup
   - ROCm Installation
   - PyTorch Installation
3. **Validate** ? Test ROCm and PyTorch

## Total Time: ~30-45 minutes (mostly automated waiting)

---

## Alternative: Command Line Power User Mode

```powershell
# Run as Administrator
cd ROCm_Installer_Win11\src\scripts
.\master_installer.ps1 -AutoYes
```

---

## What Gets Installed?

- ? WSL2 with Ubuntu 22.04
- ? AMD GPU Drivers for WSL
- ? ROCm 6.1.3 (Complete platform)
- ? PyTorch 2.1.2 + ROCm 6.1.3
- ? TorchVision & TorchAudio
- ? Environment configuration

---

## Verify Installation

```bash
# Open WSL2
wsl -d Ubuntu-22.04

# Check ROCm
ROCminfo

# Test PyTorch
python3 -c "import torch; print(f'GPU Available: {torch.cuda.is_available()}')"
```

Expected output: `GPU Available: True`

---

## Next Steps After Installation

### For Stable Diffusion Users
```bash
# Install ComfyUI
cd ~
git clone https://github.com/comfyanonymous/ComfyUI
cd ComfyUI
pip install -r requirements.txt  # Comment out torch line first!
python main.py
```

### For LLM Development
```bash
# Install Transformers
pip install transformers accelerate datasets
```

### For General ML
```bash
# Use the generated requirements template
pip install -r ~/ROCm_requirements.txt
```

---

## Troubleshooting One-Liners

| Problem | Solution |
|---------|----------|
| WSL won't start | `wsl --update && wsl --shutdown` |
| GPU not found | Update AMD drivers from [AMD.com](https://www.amd.com/en/support) |
| Torch doesn't see GPU | Reinstall PyTorch script |
| Permission errors | Run PowerShell as Administrator |

---

## Support

- ?? Full Documentation: [README.md](README.md)
- ?? Report Issues: [GitHub Issues](https://github.com/OCNGill/ROCm_Installer_Win11/issues)
- ?? Community: [AMD Forums](https://community.amd.com/)

---

## Pro Tips

?? **Backup your work**: Installation modifies system settings  
?? **Update drivers first**: Get AMD Software 24.6.1+ before starting  
?? **Don't overwrite torch**: Always comment out torch in requirements.txt  
?? **Check logs**: Located in `logs/` directory  
?? **Restart when needed**: Some steps require Windows restart  

---

**Ready? Let's go! ??**
