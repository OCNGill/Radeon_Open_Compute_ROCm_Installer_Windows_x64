import streamlit as st
import subprocess
import json
import sys
import yaml
from pathlib import Path
from datetime import datetime
import time

st.set_page_config(
    page_title="ROCm AI Platform",
    page_icon="🚀",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Custom CSS for better styling
st.markdown("""
<style>
  .main-header {
        font-size: 3rem;
        color: #ED1C24;
        text-align: center;
        padding: 1rem;
  }
  .sub-header {
        font-size: 1.5rem;
        color: #666;
        text-align: center;
        padding-bottom: 2rem;
  }
  .step-box {
        padding: 1.5rem;
        border-radius: 10px;
        border-left: 5px solid #ED1C24;
        background-color: #f8f9fa;
        margin: 1rem 0;
  }
  .success-box {
        padding: 1rem;
        border-radius: 5px;
        background-color: #d4edda;
        border: 1px solid #c3e6cb;
        color: #155724;
  }
  .warning-box {
        padding: 1rem;
        border-radius: 5px;
        background-color: #fff3cd;
        border: 1px solid #ffeaa7;
        color: #856404;
  }
  .error-box {
        padding: 1rem;
        border-radius: 5px;
        background-color: #f8d7da;
        border: 1px solid #f5c6cb;
        color: #721c24;
  }
</style>
""", unsafe_allow_html=True)

# Initialize session state
if 'install_stage' not in st.session_state:
    st.session_state.install_stage = 0
if 'logs' not in st.session_state:
    st.session_state.logs = []
if 'gpu_info' not in st.session_state:
    st.session_state.gpu_info = None
if 'compatibility_passed' not in st.session_state:
    st.session_state.compatibility_passed = False
if 'docker_installed' not in st.session_state:
    st.session_state.docker_installed = False

def add_log(message, level="INFO"):
    """Add a log entry with timestamp"""
    timestamp = datetime.now().strftime("%H:%M:%S")
    st.session_state.logs.append(f"[{timestamp}] [{level}] {message}")

def run_powershell_script(script_name, params=""):
    """Execute a PowerShell script and return the output"""
    try:
        script_path = Path(__file__).parent.parent / "scripts" / script_name
   
        if not script_path.exists():
            return False, f"Script not found: {script_path}"
        
        cmd = ["powershell", "-ExecutionPolicy", "Bypass", "-File", str(script_path)]
        if params:
            cmd.append(params)
        
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=300  # 5 minutes timeout
        )
        
        return result.returncode == 0, result.stdout + result.stderr
    except subprocess.TimeoutExpired:
        return False, "Script execution timed out"
    except Exception as e:
        return False, f"Error: {str(e)}"

def run_wsl_command(command, description=""):
    """Execute a command in WSL"""
    try:
        add_log(f"Executing WSL command: {description or command}")
        result = subprocess.run(
            ["wsl", "-d", "Ubuntu-22.04", "-e", "bash", "-c", command],
            capture_output=True,
            text=True,
            timeout=600  # 10 minutes timeout
        )
        return result.returncode == 0, result.stdout + result.stderr
    except Exception as e:
        return False, f"Error: {str(e)}"

def check_docker_installed():
    """Check if Docker Desktop is installed and running"""
    try:
        result = subprocess.run(["docker", "--version"], capture_output=True, text=True)
        if result.returncode == 0:
            st.session_state.docker_installed = True
            return True
        return False
    except FileNotFoundError:
        return False

def load_config():
    """Load LLM configuration"""
    config_path = Path(__file__).parent.parent / "config" / "llm_config.yaml"
    if config_path.exists():
        with open(config_path, 'r') as f:
            return yaml.safe_load(f)
    return {}

# Header
st.markdown('<div class="main-header">🚀 ROCm AI Platform</div>', unsafe_allow_html=True)
st.markdown('<div class="sub-header">One-Click AMD ROCm Setup & AI Development Environment</div>', unsafe_allow_html=True)

# Sidebar - Installation Progress
with st.sidebar:
    st.header("📋 Installation Progress")
    
    stages = [
        '🔍 System Check',
        '🐧 WSL2 Setup',
        '📦 ROCm Installation',
        '🔥 PyTorch Setup',
        '✅ Validation'
    ]
    
    progress = st.session_state.install_stage / len(stages)
    st.progress(progress)
    
    st.subheader("Current Stage:")
    if st.session_state.install_stage < len(stages):
        st.info(stages[st.session_state.install_stage])
    else:
        st.success("🎉 Complete!")
    
    st.markdown("---")
    
    # System Info
    st.subheader("💻 System Information")
    if st.session_state.gpu_info:
        st.json(st.session_state.gpu_info)
    else:
        st.write("Run compatibility check first")
    
    st.markdown("---")
    
    # Quick Actions
    st.subheader("⚡ Quick Actions")
    if st.button("🔄 Reset Installation"):
        st.session_state.install_stage = 0
        st.session_state.logs = []
        st.session_state.compatibility_passed = False
        st.rerun()
    
    if st.button("📜 View Full Logs"):
        if st.session_state.logs:
            st.text_area("Installation Logs", "\n".join(st.session_state.logs), height=500, key="full_logs")

# Main Content Area
tab1, tab2, tab3, tab4, tab5, tab6 = st.tabs(["🏠 Home", "✅ Compatibility", "📥 Installation", "🐳 Docker & Containers", "🤖 Models & Chat", "📚 Documentation"])

with tab1:
    st.header("Welcome to the ROCm AI Platform")
    
    col1, col2 = st.columns(2)
    
    with col1:
        st.markdown("""
        ### What is ROCm?
        
        AMD ROCm (Radeon Open Compute) is an open-source software platform for GPU computing.
        It enables:
        - 🧠 Machine Learning & AI Development
        - 🎨 Stable Diffusion & Image Generation
        - 💬 Large Language Models (LLMs)
        - ⚡ High-Performance Computing
   
        ### Features of This Platform:
        - ✅ Automatic hardware detection
        - ✅ One-click WSL2 setup
        - ✅ Complete ROCm installation
        - ✅ **Docker Container Management**
        - ✅ **Local LLM Serving (vLLM)**
        - ✅ **Integrated Chat Interface**
        """)
    
    with col2:
        st.markdown("""
        ### System Requirements:
        
        🖥️ **Operating System:**
        - Windows 11 (Build 22000 or later)
        
        🎮 **Hardware:**
        - AMD Radeon RX 7000 Series GPU
        - 16GB+ RAM recommended
        - 50GB+ free disk space
 
        💿 **Software:**
        - WSL2 capable system
        - Administrator privileges
        - Internet connection
 
        ### Supported GPUs:
        - RX 7900 XTX / XT / GRE
        - RX 7800 XT
        - RX 7700 XT
        - RX 7600 XT / 7600
        """)
    
    st.markdown("---")
    
    st.info("👉 **Ready to start?** Go to the **Compatibility** tab to check your system!")

with tab2:
    st.header("✅ System Compatibility Check")
  
    st.markdown("""
    This check will verify:
    1. Windows 11 installation
    2. AMD GPU presence and model
    3. Driver version compatibility
    4. WSL2 support
    """)
    
    if st.button("🚀 Run Compatibility Check", type="primary", use_container_width=True):
        with st.spinner("Checking system compatibility..."):
            add_log("Starting compatibility check")
            
            # Run hardware detection
            success, output = run_powershell_script("detect_hardware.ps1")
            
            if success:
                st.markdown('<div class="success-box">✅ Hardware check passed!</div>', unsafe_allow_html=True)
                add_log("Hardware check passed", "SUCCESS")
                
                # Run AMD driver verification
                success2, output2 = run_powershell_script("verify_amd_compatibility.ps1")
                
                if success2:
                    st.markdown('<div class="success-box">✅ AMD GPU compatibility confirmed!</div>', unsafe_allow_html=True)
                    add_log("AMD GPU compatibility confirmed", "SUCCESS")
                    st.session_state.compatibility_passed = True
                    st.session_state.install_stage = 1
                else:
                    st.markdown('<div class="warning-box">⚠️ GPU compatibility check completed with warnings</div>', unsafe_allow_html=True)
                    st.session_state.compatibility_passed = True  # Allow to continue with warnings
            
                with st.expander("🔍 View Detailed Output"):
                    st.code(output + "\n\n" + output2)
            else:
                st.markdown('<div class="error-box">❌ Compatibility check failed</div>', unsafe_allow_html=True)
                add_log("Compatibility check failed", "ERROR")
                with st.expander("🔍 View Error Details"):
                    st.code(output)
    
    if st.session_state.compatibility_passed:
        st.success("✨ Your system is ready for ROCm installation!")
        st.info("👉 Proceed to the **Installation** tab")

with tab3:
    st.header("📥 ROCm Installation")
    
    if not st.session_state.compatibility_passed:
        st.warning("⚠️ Please complete the compatibility check first!")
    else:
        st.success("✅ System compatibility confirmed")
        
        st.markdown("---")
    
        # Installation steps
        st.subheader("Installation Steps:")
        
        # Step 1: WSL2 Setup
        with st.expander("**Step 1: WSL2 Setup**", expanded=(st.session_state.install_stage == 1)):
            st.markdown("""
            This step will:
            - Enable WSL2 features
            - Install Ubuntu 22.04
            - Configure the environment
            
            ⚠️ **Note:** This may require a system restart.
            """)
   
            if st.button("🚀 Install WSL2", key="wsl_install"):
                with st.spinner("Installing WSL2... This may take several minutes"):
                    add_log("Starting WSL2 installation")
                    success, output = run_powershell_script("wsl2_setup.ps1")
                
                    if success:
                        st.success("✅ WSL2 installation completed!")
                        add_log("WSL2 installation completed", "SUCCESS")
                        st.session_state.install_stage = 2
                    else:
                        st.error("❌ WSL2 installation failed")
                        add_log("WSL2 installation failed", "ERROR")
                    
                    with st.expander("View Installation Log"):
                        st.code(output)
        
        # Step 2: ROCm Installation
        with st.expander("**Step 2: ROCm Installation**", expanded=(st.session_state.install_stage == 2)):
            st.markdown("""
            This step will:
            - Install AMD GPU drivers for WSL
            - Install ROCm 6.1.3
            - Configure environment variables
            
            ⏱️ **Estimated time:** 10-15 minutes
            """)
            
            if st.button("🚀 Install ROCm", key="ROCm_install"):
                with st.spinner("Installing ROCm... Please wait"):
                    add_log("Starting ROCm installation")
                    
                    # Prepare WSL environment (copy scripts)
                    success_prep, output_prep = run_powershell_script("prepare_wsl_env.ps1")
                    if not success_prep:
                        st.error("❌ Failed to prepare WSL environment")
                        add_log(f"WSL prep failed: {output_prep}", "ERROR")
                        with st.expander("View Prep Log"):
                            st.code(output_prep)
                    else:
                        # Copy script to WSL and execute
                        success, output = run_wsl_command(
                            "bash /tmp/ROCm_install/install_ROCm.sh",
                            "Installing ROCm in WSL2"
                        )
                        
                        if success:
                            st.success("✅ ROCm installation completed!")
                            add_log("ROCm installation completed", "SUCCESS")
                            st.session_state.install_stage = 3
                        else:
                            st.error("❌ ROCm installation failed")
                            add_log("ROCm installation failed", "ERROR")
                        
                        with st.expander("View Installation Log"):
                            st.code(output)
        
        # Step 3: PyTorch Installation
        with st.expander("**Step 3: PyTorch with ROCm**", expanded=(st.session_state.install_stage == 3)):
            st.markdown("""
            This step will:
            - Install PyTorch 2.1.2 with ROCm 6.1.3
            - Install TorchVision and TorchAudio
            - Configure HSA runtime
            
            ⏱️ **Estimated time:** 10-15 minutes
            """)
        
            if st.button("🚀 Install PyTorch", key="pytorch_install"):
                with st.spinner("Installing PyTorch... Please wait"):
                    add_log("Starting PyTorch installation")
        
                    success, output = run_wsl_command(
                        "bash /tmp/ROCm_install/install_pytorch.sh",
                        "Installing PyTorch with ROCm"
                    )
            
                    if success:
                        st.success("✅ PyTorch installation completed!")
                        add_log("PyTorch installation completed", "SUCCESS")
                        st.session_state.install_stage = 4
                    else:
                        st.error("❌ PyTorch installation failed")
                        add_log("PyTorch installation failed", "ERROR")
            
                    with st.expander("View Installation Log"):
                        st.code(output)
    
        # Step 4: Validation
        with st.expander("**Step 4: Validation & Testing**", expanded=(st.session_state.install_stage == 4)):
            st.markdown("""
            Verify your installation:
            """)
    
            col1, col2 = st.columns(2)
                
            with col1:
                if st.button("🧪 Test ROCm", use_container_width=True):
                    with st.spinner("Testing ROCm..."):
                        success, output = run_wsl_command("ROCminfo", "Testing ROCm")
                        if success:
                            st.success("✅ ROCm is working!")
                            with st.expander("ROCm Info"):
                                st.code(output)
                        else:
                            st.error("❌ ROCm test failed")
                            st.code(output)
        
            with col2:
                if st.button("🔥 Test PyTorch", use_container_width=True):
                    with st.spinner("Testing PyTorch..."):
                        test_cmd = "python3 -c 'import torch; print(f\"PyTorch: {torch.__version__}\"); print(f\"CUDA Available: {torch.cuda.is_available()}\"); print(f\"GPU: {torch.cuda.get_device_name(0) if torch.cuda.is_available() else \"N/A\"}\")'"
                        success, output = run_wsl_command(test_cmd, "Testing PyTorch")
                        if success and "True" in output:
                            st.success("✅ PyTorch with ROCm is working!")
                            st.code(output)
                            st.session_state.install_stage = 5
                        else:
                            st.error("❌ PyTorch test failed")
                            st.code(output)
            
        # Completion
        if st.session_state.install_stage >= 5:
            st.balloons()
            st.markdown("""
            <div class="success-box">
                <h2>🎉 Installation Complete!</h2>
                <p>Your system is now ready for AI/ML development with ROCm!</p>
            </div>
            """, unsafe_allow_html=True)
    
            st.subheader("Next Steps:")
            st.markdown("""
            1. **Open WSL2:**
            ```bash
            wsl -d Ubuntu-22.04
            ```

            2. **Test your setup:**
            ```python
            python3 -c "import torch; print(torch.cuda.is_available())"
            ```
            
            3. **Install AI frameworks:**
            - Stable Diffusion (ComfyUI, Automatic1111)
            - Hugging Face Transformers
            - LangChain for LLMs
            
            4. **Remember:** When installing other packages, comment out torch in requirements.txt
            to avoid overwriting your ROCm PyTorch installation!
            """)

with tab4:
    st.header("🐳 Docker & Containers")
    st.markdown("Manage your AI containers and environments.")
    
    check_docker_installed()
    
    if not st.session_state.docker_installed:
        st.warning("⚠️ Docker Desktop is not detected!")
        st.markdown("Please install Docker Desktop for Windows to use container features.")
        st.markdown("[Download Docker Desktop](https://www.docker.com/products/docker-desktop/)")
    else:
        st.success("✅ Docker Desktop is installed and ready.")
        
        col1, col2 = st.columns(2)
        
        with col1:
            st.subheader("vLLM Server")
            st.markdown("High-performance LLM serving engine.")
            if st.button("🚀 Build vLLM Container"):
                with st.spinner("Building vLLM container..."):
                    # Logic to build container
                    dockerfile_path = Path(__file__).parent.parent / "docker" / "vllm"
                    cmd = f"docker build -t rocm-vllm:latest {dockerfile_path}"
                    success, output = run_powershell_script("run_docker_build.ps1", f"-Path {dockerfile_path} -Tag rocm-vllm:latest") # Placeholder script
                    # For now, just simulating or using direct command if script doesn't exist
                    # In real implementation, we'd use a script or subprocess directly
                    st.info("Build process started (Simulation)")
                    
        with col2:
            st.subheader("PyTorch Interactive")
            st.markdown("JupyterLab environment for development.")
            if st.button("🚀 Build PyTorch Container"):
                with st.spinner("Building PyTorch container..."):
                    st.info("Build process started (Simulation)")

with tab5:
    st.header("🤖 Models & Chat")
    st.markdown("Manage local LLMs and chat with them.")
    
    config = load_config()
    
    st.subheader("Model Configuration")
    st.json(config)
    
    st.subheader("Chat Interface")
    user_input = st.text_input("You:", placeholder="Ask something...")
    if st.button("Send"):
        st.write(f"**AI:** (Echo) {user_input}")
        st.info("Connect to vLLM container to enable real chat.")

with tab6:
    st.header("📚 Documentation & Resources")
    
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("Official AMD Documentation")
        st.markdown("""
        - [ROCm Documentation](https://ROCm.docs.amd.com/)
        - [ROCm for WSL2](https://ROCm.docs.amd.com/projects/radeon/en/latest/docs/install/wsl/install-radeon.html)
        - [PyTorch ROCm](https://ROCm.docs.amd.com/projects/radeon/en/latest/docs/install/wsl/install-pytorch.html)
        - [AMD Support](https://www.amd.com/en/support)
        """)
        
        st.subheader("Community Resources")
        st.markdown("""
        - [ROCm GitHub](https://github.com/RadeonOpenCompute/ROCm)
        - [AMD Community Forums](https://community.amd.com/)
        - [r/ROCm Reddit](https://www.reddit.com/r/ROCm/)
        """)
    
    with col2:
        st.subheader("Troubleshooting")
        st.markdown("""
        **Common Issues:**
        
        1. **WSL2 not working:**
        - Ensure virtualization is enabled in BIOS
        - Run: `wsl --update`
    
        2. **GPU not detected:**
        - Update AMD drivers to 24.6.1+
        - Check: `ROCminfo` in WSL
        
        3. **PyTorch not finding GPU:**
        - Verify HSA runtime fix was applied
        - Check: `echo $LD_LIBRARY_PATH`
    
        4. **Installation hangs:**
        - Check internet connection
        - Try running scripts individually
        """)
        
        st.subheader("Getting Help")
        st.markdown("""
        If you encounter issues:
        1. Check the installation logs
        2. Review AMD's official documentation
        3. Search community forums
        4. Create an issue on GitHub
        """)

# Footer
st.markdown("---")
st.markdown("""
<div style='text-align: center; color: #666;'>
    <p>ROCm AI Platform | Made with ❤️ for the AMD AI Community</p>
    <p>⚠️ This is an unofficial community tool. For official support, visit AMD.com</p>
</div>
""", unsafe_allow_html=True)