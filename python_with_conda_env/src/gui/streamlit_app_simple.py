import streamlit as st
import subprocess
from pathlib import Path
from datetime import datetime

st.set_page_config(
    page_title="ROCm Windows 11 Installer",
    page_icon="??",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Custom CSS
st.markdown("""
<style>
.main-header {font-size: 3rem; color: #ED1C24; text-align: center; padding: 1rem;}
.sub-header {font-size: 1.5rem; color: #666; text-align: center; padding-bottom: 2rem;}
.success-box {padding: 1rem; border-radius: 5px; background-color: #d4edda; border: 1px solid #c3e6cb; color: #155724;}
.warning-box {padding: 1rem; border-radius: 5px; background-color: #fff3cd; border: 1px solid #ffeaa7; color: #856404;}
.error-box {padding: 1rem; border-radius: 5px; background-color: #f8d7da; border: 1px solid #f5c6cb; color: #721c24;}
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
        
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
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
  timeout=600
        )
        return result.returncode == 0, result.stdout + result.stderr
    except Exception as e:
        return False, f"Error: {str(e)}"

# Header
st.markdown('<div class="main-header">?? ROCm Windows 11 Installer</div>', unsafe_allow_html=True)
st.markdown('<div class="sub-header">One-Click AMD ROCm Setup for AI & Machine Learning</div>', unsafe_allow_html=True)

# Sidebar
with st.sidebar:
    st.header("?? Installation Progress")
    stages = ['? System Check', '?? WSL2 Setup', '?? ROCm Installation', '?? PyTorch Setup', '? Validation']
    progress = st.session_state.install_stage / len(stages)
    st.progress(progress)
    
    st.subheader("Current Stage:")
    if st.session_state.install_stage < len(stages):
    st.info(stages[st.session_state.install_stage])
    else:
     st.success("?? Complete!")
    
    st.markdown("---")
    st.subheader("? Quick Actions")
    
    if st.button("?? Reset Installation"):
        st.session_state.install_stage = 0
   st.session_state.logs = []
        st.session_state.compatibility_passed = False
        st.rerun()

# Main tabs
tab1, tab2, tab3, tab4 = st.tabs(["?? Home", "?? Compatibility", "?? Installation", "?? Documentation"])

with tab1:
    st.header("Welcome to the ROCm Windows 11 Installer")
    col1, col2 = st.columns(2)
    
    with col1:
        st.markdown("""
    ### What is ROCm?
- ?? Machine Learning & AI Development
        - ?? Stable Diffusion & Image Generation
        - ?? Large Language Models (LLMs)
      """)
    
    with col2:
        st.markdown("""
        ### System Requirements:
        - Windows 11 (Build 22000+)
        - AMD Radeon RX 7000 Series GPU
        - 16GB+ RAM recommended
        """)

with tab2:
    st.header("?? System Compatibility Check")
    
    if st.button("?? Run Compatibility Check", type="primary", use_container_width=True):
        with st.spinner("Checking system compatibility..."):
            add_log("Starting compatibility check")
    success, output = run_powershell_script("detect_hardware.ps1")
     
  if success:
        st.markdown('<div class="success-box">? Hardware check passed!</div>', unsafe_allow_html=True)
       add_log("Hardware check passed", "SUCCESS")
           st.session_state.compatibility_passed = True
         st.session_state.install_stage = 1
else:
st.markdown('<div class="error-box">? Compatibility check failed</div>', unsafe_allow_html=True)
    add_log("Compatibility check failed", "ERROR")
       
            with st.expander("?? View Details"):
  st.code(output)

with tab3:
    st.header("?? ROCm Installation")
    
    if not st.session_state.compatibility_passed:
        st.warning("?? Please complete the compatibility check first!")
    else:
        st.success("? System compatibility confirmed")

with tab4:
    st.header("?? Documentation & Resources")
    st.markdown("""
    - [ROCm Documentation](https://ROCm.docs.amd.com/)
  - [PyTorch ROCm](https://ROCm.docs.amd.com/projects/radeon/en/latest/docs/install/wsl/install-pytorch.html)
    - [AMD Support](https://www.amd.com/en/support)
    """)

# Footer
st.markdown("---")
st.markdown("<div style='text-align: center; color: #666;'><p>ROCm Windows 11 Installer | Made with ?? for the AMD AI Community</p></div>", unsafe_allow_html=True)
