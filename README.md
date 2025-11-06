# Radeon_Open_Compute_ROCm_Installer_Windows_x64 (v1.3)

This repository provides a unified environment for deploying and testing AMD ROCm on Windows x64 systems.
It consolidates Python-based workflows with Conda environments and a standalone MSI installer build system.

## Quick Start - Download the MSI Installer

**For most users, download the one-click installer:**

**[ROCm_windows_x64_1.3.msi](ROCm_windows_x64_1.3.msi)** - One-click installer (coming soon via GitHub Actions)

*Note: The MSI will be automatically built and released when you push the v1.3 tag. Check the Actions tab.*

## Repository structure
- **docs/** — Documentation
- **revision_documentation/** — Archived and deduplicated revision documents
- **python_with_conda_env/** — Python-specific workflows with Conda environment
- **ROCm_windows_installer_x64/** — MSI installer build system
- **claude_skills_for_AI_workflows/** — Claude skills prompts for AI workflow automation
- **testing/** — Testing environments (VM, Sandbox)

---

**Status as of End of Day (v1.3) - 2025-10-27:**

Branches consolidated, documentation cleaned, repo renamed, Claude skills folder added, and Conda environment synchronized.

**Tomorrow:** Testing begins on Gillsystems_main with Ryzen 5900X + Radeon 7900XTX. VM and Windows Sandbox are already prepared.

---

## Security Notice: Self-Signed Installer

This installer is currently signed with a **self-signed certificate** for community testing and distribution.

**What this means:**
- Windows SmartScreen will display a warning when you run the installer
- This is **EXPECTED** and **SAFE** for self-signed applications
- The installer is built from open-source code you can inspect

**To install:**
1. Download the MSI from Releases
2. Right-click and select "Run as Administrator"
3. When SmartScreen appears, click "More info"
4. Click "Run anyway"
5. Follow the installation wizard

**Why self-signed?**
- Commercial code signing certificates cost $300-500/year
- This is a community project without corporate funding
- All source code is available for review on GitHub

**Future:** We plan to obtain a commercial certificate once the project demonstrates community adoption and funding becomes available.

---

# ROCm Windows Installer
## **One-Click AMD ROCm Setup for AI & Machine Learning on Windows 10/11**

[![Windows 10/11](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D6?style=flat&logo=windows&logoColor=white)](https://www.microsoft.com/windows)
[![ROCm](https://img.shields.io/badge/ROCm-6.1.3-ED1C24?style=flat&logo=amd&logoColor=white)](https://ROCm.docs.amd.com/)
[![Python](https://img.shields.io/badge/Python-3.10-3776AB?style=flat&logo=python&logoColor=white)](https://www.python.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## Project and Work Product Description

This project provides a **rock-solid, production-ready** automated installer for AMD's ROCm (Radeon Open Compute) platform on Windows 10 Pro and Windows 11 systems using WSL2. It fills a critical gap left by AMD by providing a streamlined, user-friendly solution for AI enthusiasts, data scientists, and machine learning engineers who want to leverage AMD Radeon RX 7000 Series GPUs for their work. 

The installer addresses the complex, error-prone manual installation process by providing:
- **Automated hardware detection** and compatibility verification
- **One-click WSL2 setup** with Ubuntu 22.04
- **Complete ROCm 6.1.3 installation** with all dependencies
- **PyTorch 2.1.2 + ROCm** integration with proper HSA runtime configuration
- **Professional GUI** for monitoring and control with comprehensive logging
- **Validation and testing** to ensure everything works before you start coding

**Problem Statement:** AMD provides excellent GPU hardware but lacks an easy, automated installation path for Windows users wanting to run ROCm-powered AI applications. Manual installation involves dozens of steps across multiple systems (Windows and Linux) with numerous potential failure points.

**Solution:** This installer automates the entire process from hardware detection through validation, making ROCm accessible to everyone with compatible hardware.

---

## Description of Solution

### Core Workflow

The ROCm Windows 11 Installer orchestrates a complete installation workflow:

1. **System Compatibility Check**
   - Verifies Windows 10 Pro/Enterprise/Education (Build 19041+) or Windows 11
   - Detects AMD Radeon RX 7000 Series GPU or Ryzen AI APU
   - Checks AMD driver version (25.9.2+)
   - Confirms WSL2 capability and Hyper-V support
   - Validates Windows edition (Pro/Enterprise/Education required)

2. **WSL2 Environment Setup**
   - Enables Windows Subsystem for Linux features
   - Installs Ubuntu 22.04 (tested and verified version)
   - Configures WSL2 as default
   - Sets up networking and GPU passthrough

3. **ROCm Installation**
   - Downloads AMD GPU install package (6.1.3)
   - Installs AMDGPU drivers for WSL
   - Installs ROCm runtime and toolchain
   - Configures environment variables

4. **PyTorch Integration**
   - Installs Python 3.10 and dependencies
   - Downloads PyTorch 2.1.2 + ROCm 6.1.3 wheels
   - Installs TorchVision and TorchAudio
   - Fixes HSA runtime library linking
   - Validates GPU detection

5. **Validation & Testing**
   - Runs `ROCminfo` to verify GPU detection
   - Tests PyTorch CUDA/ROCm availability
   - Creates test tensor on GPU
   - Generates installation report

### Minimum Viable Product (MVP) Features

**V1.0 Delivered:**
-  Complete automated installation pipeline
-  Professional Streamlit web interface
-  Comprehensive PowerShell automation scripts
-  Bash scripts for WSL2-side installation
-  Real-time progress tracking
-  Detailed logging system
-  Error handling and recovery guidance
-  System compatibility checking
-  Installation validation and testing
-  Requirements template for ML packages

**Future Enhancements (V2.0+):**
- Automatic rollback on failures
- Modular component installation
- Digital signing for distribution
- Pre-configured ML environment templates
- Stable Diffusion quick-setup wizard
- LLM framework installers (LM Studio, Ollama integration)
- Performance benchmarking tools
- Troubleshooting diagnostic wizard

---

## Solution Design (High-Level)

### Architecture Diagram

```
## Windows 10/11 Host

## Streamlit Web Interface (Python)
- Progress Tracking
- User Controls
- Log Visualization

## PowerShell Automation Layer
- Hardware Detection
- Driver Verification
- WSL2 Setup
- Master Orchestrator

## WSL2 Bridge

## WSL2 Ubuntu 22.04

### Bash Installation Scripts
- ROCm Installation
- PyTorch Setup

### ROCm Runtime Environment
- /opt/rocm/
- PyTorch 2.1.2 + ROCm
- CUDA/ROCm API Layer

## GPU Passthrough

## AMD Radeon RX 7000 Series GPU
- Hardware Acceleration
- ROCm 6.1.3 Compatible Drivers

### Component Interaction Flow

```mermaid
graph TD
    A[User] --> B[Streamlit GUI]
    B --> C[Hardware Check]
    C --> D[Driver Verification]
    D --> E[WSL2 Setup]
  E --> F[Ubuntu 22.04 Installation]
    F --> G[ROCm Installation]
    G --> H[PyTorch Installation]
    H --> I[Validation Tests]
    I --> J[Ready for AI/ML Development]
```

---

## Solution Code Description

### Project Structure

```
ROCm_Win11_installer/
	src/
	gui/
	streamlit_app.py          # Main web interface?    scripts/
    detect_hardware.ps1        # Windows hardware detection
	verify_amd_compatibility.ps1 # AMD GPU/driver check
	wsl2_setup.ps1    # WSL2 installation
	master_installer.ps1       # Master orchestrator
	install_ROCm.sh            # ROCm installation (WSL)
	install_pytorch.sh         # PyTorch installation (WSL)
	utils/
	logging_utils.py           # Logging utilities
	logs/          # Installation logs
	docs/       # Documentation
	environment.yml          # Conda environment
	requirements.txt# Python dependencies
	README.md              # This file
```

### Key Components

#### 1. **Streamlit Web Interface** (`src/gui/streamlit_app.py`)
- Modern, responsive UI with progress tracking
- Real-time log streaming
- System information display
- Installation control panel
- Validation testing interface

#### 2. **PowerShell Scripts** (`src/scripts/*.ps1`)
- **detect_hardware.ps1**: Detects AMD GPU and Windows version
- **verify_amd_compatibility.ps1**: Validates driver versions and GPU compatibility
- **wsl2_setup.ps1**: Automates WSL2 installation and configuration
- **master_installer.ps1**: Orchestrates the entire installation process

#### 3. **Bash Scripts** (`src/scripts/*.sh`)
- **install_ROCm.sh**: Installs ROCm 6.1.3 in WSL2 Ubuntu
- **install_pytorch.sh**: Installs PyTorch with ROCm support and fixes HSA runtime

#### 4. **Logging System** (`src/utils/logging_utils.py`)
- Timestamped logs
- Multiple log levels (INFO, WARNING, ERROR, SUCCESS)
- File and console output
- System information capture

---

## Actual Working Product Code

### External Dependencies

#### Python Packages (requirements.txt)
```
streamlit>=1.30.0          # Web interface framework
psutil>=5.9.0            # System and process utilities
requests>=2.31.0           # HTTP library
PyYAML>=6.0                # YAML parser
tqdm>=4.65.0            # Progress bars
watchdog>=3.0.0 # File system monitoring
streamlit-option-menu>=0.3.6  # UI components
```

#### Conda Environment (environment.yml)
```yaml
name: ROCm_installer_env
channels:
  - conda-forge
  - defaults
dependencies:
  - python=3.10
  - pip
  - streamlit
  - psutil
  - pywin32
  - pyyaml
  - rich
  - typer
  - requests
  - pytest
  - black
  - flake8
```

### Custom Modules

All custom code is thoroughly documented and includes:
- Hardware detection algorithms
- WSL2 automation logic
- ROCm installation orchestration
- PyTorch integration with HSA runtime fixes
- Comprehensive error handling
- Progress tracking system

### Code Links

- [Main Repository](https://github.com/OCNGill/ROCm_Installer_Win11)
- [Streamlit GUI](src/gui/streamlit_app.py)
- [Installation Scripts](src/scripts/)
- [Documentation](docs/)

---

## Application Instructions

### Prerequisites

- **Operating System**: Windows 10 Pro/Enterprise/Education (Build 19041+) OR Windows 11
- **Hardware**: AMD Radeon RX 7000 Series GPU
  - RX 7900 XTX, XT, GRE
  - RX 7800 XT
  - RX 7700 XT
  - RX 7600 XT, 7600
  - Ryzen AI APUs (Radeon 890M, 880M, 780M)
- **RAM**: 16GB+ recommended (32GB for large models)
- **Storage**: 50GB+ free disk space
- **Network**: Internet connection for downloads
- **Privileges**: Administrator access required
- **Requirements**: 
  - Hyper-V capable system (not available on Windows Home editions)
  - Virtualization enabled in BIOS/UEFI
  - AMD Adrenalin drivers 25.9.2 or later

> **Note**: Windows 10 Home and Windows 11 Home editions are **NOT supported** because they lack Hyper-V functionality required for WSL2.

### Installation Steps

#### Method 1: GUI Installation (Recommended)

1. **Clone the Repository**
   ```bash
   git clone https://github.com/OCNGill/ROCm_Installer_Win11.git
   cd ROCm_Installer_Win11
   ```

2. **Set Up Python Environment**
   ```bash
   # Using Conda (recommended)
   conda env create -f environment.yml
   conda activate ROCm_installer_env

   # OR using pip
   pip install -r requirements.txt
   ```

3. **Launch the Installer**
   ```bash
   streamlit run src/gui/streamlit_app.py
   ```

4. **Follow the Web Interface**
   - Open your browser (automatically opens to http://localhost:8501)
   - Navigate through the tabs:
     - **Home**: Overview and requirements
     - **Compatibility**: Run system checks
  - **Installation**: Execute installation steps
     - **Documentation**: Access help resources

5. **Complete Installation**
   - Click through each installation step
   - Monitor progress in real-time
   - Review logs for any issues
- Run validation tests

#### Method 2: Command-Line Installation

1. **Run as Administrator**
   ```powershell
   # Open PowerShell as Administrator
   cd ROCm_Installer_Win11\src\scripts
   ```

2. **Execute Master Installer**
   ```powershell
   .\master_installer.ps1
   ```

3. **Follow Prompts**
   - Confirm each installation step
   - Wait for completion
   - Review final summary

### Post-Installation

1. **Verify Installation**
   ```bash
   # Open WSL2
   wsl -d Ubuntu-22.04

# Check ROCm
   ROCminfo

   # Test PyTorch
   python3 -c "import torch; print(torch.cuda.is_available())"
   ```

2. **Install AI Frameworks** (Optional)
   ```bash
   # Inside WSL2
   pip3 install -r ~/ROCm_requirements.txt
   ```

3. **Start Development**
   - Your system is now ready for AI/ML projects!
   - Compatible with Stable Diffusion, LLMs, and more

### Important Guidelines

- **DO NOT** overwrite PyTorch when installing other packages
- **ALWAYS** comment out `torch` lines in requirements.txt files
- **KEEP** logs for troubleshooting (stored in `logs/` directory)
- **UPDATE** AMD drivers regularly for best performance
- **BACKUP** your work before major system changes

---

## Future Enhancements

### Version 2.0 Roadmap
- **Automated Rollback**: Undo installation if errors occur
- **Component Selection**: Choose which parts to install
- **Profile Manager**: Save/load installation profiles
- **Update Checker**: Automatically check for ROCm updates

### Version 3.0 Roadmap
- **Pre-configured Environments**: One-click setups for:
  - Stable Diffusion (ComfyUI, Automatic1111)
  - LLM Development (LM Studio, Ollama)
  - General ML (TensorFlow, JAX)
- **Performance Tuning**: Optimize ROCm for specific GPUs
- **Cloud Integration**: Backup and sync configurations
- **Community Repository**: Share working configurations

### Version 4.0+ Vision
- **Multi-GPU Support**: Manage multiple AMD GPUs
- **Remote Installation**: Set up systems remotely
- **CI/CD Integration**: Automate testing and deployment
- **Enterprise Features**: Bulk deployment, licensing

---

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| WSL2 not installing | Enable virtualization in BIOS |
| GPU not detected | Update AMD drivers to 24.6.1+ |
| PyTorch can't find GPU | Verify HSA runtime fix applied |
| Installation hangs | Check internet connection, run individually |
| Permission denied | Run PowerShell as Administrator |

### Getting Help

1. **Check Logs**: Review installation logs in `logs/` directory
2. **AMD Documentation**: [ROCm for WSL2](https://ROCm.docs.amd.com/projects/radeon/en/latest/docs/install/wsl/install-radeon.html)
3. **Community Forums**: [AMD Community](https://community.amd.com/)
4. **GitHub Issues**: [Create an issue](https://github.com/OCNGill/ROCm_Installer_Win11/issues)

---

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

---

## License

MIT License - see [LICENSE](LICENSE) file for details

---

## Acknowledgments

- **AMD** for ROCm platform and documentation
- **Microsoft** for WSL2 technology
- **Streamlit** for the excellent GUI framework
- **Community Contributors** for testing and feedback

---

## Contact & Support

- **GitHub**: [OCNGill/ROCm_Installer_Win11](https://github.com/OCNGill/ROCm_Installer_Win11)
- **Issues**: [Report bugs or request features](https://github.com/OCNGill/ROCm_Installer_Win11/issues)

---

## 💖 Support / Donate

If you find this project helpful, you can support ongoing work — thank you!

<p align="center">
	<img src="qr-paypal.png" alt="PayPal QR code" width="180" style="margin:8px;">
	<img src="qr-venmo.png" alt="Venmo QR code" width="180" style="margin:8px;">
</p>


**Donate:**

- [![PayPal](https://img.shields.io/badge/PayPal-Donate-009cde?logo=paypal&logoColor=white)](https://paypal.me/gillsystems) https://paypal.me/gillsystems
- [![Venmo](https://img.shields.io/badge/Venmo-Donate-3d95ce?logo=venmo&logoColor=white)](https://venmo.com/Stephen-Gill-007) https://venmo.com/Stephen-Gill-007

---


<p align="center">
	<img src="Gillsystems_logo_with_donation_qrcodes.png" alt="Gillsystems logo with QR codes and icons" width="800">
</p>

<p align="center">
	<a href="https://paypal.me/gillsystems"><img src="paypal_icon.png" alt="PayPal" width="32" style="vertical-align:middle;"></a>
	<a href="https://venmo.com/Stephen-Gill-007"><img src="venmo_icon.png" alt="Venmo" width="32" style="vertical-align:middle;"></a>
</p>

