import streamlit as st
import subprocess
import json
from pathlib import Path

st.set_page_config(
    page_title="ROCm Windows 11 Installer",
    page_icon="??",
    layout="wide"
)

def run_hardware_check():
    try:
        script_path = Path(__file__).parent.parent / "scripts" / "detect_hardware.ps1"
        result = subprocess.run(
            ["powershell", "-ExecutionPolicy", "Bypass", "-File", str(script_path)],
            capture_output=True,
            text=True
        )
        return result.stdout
    except Exception as e:
        return f"Error running hardware check: {str(e)}"

st.title("?? ROCm Windows 11 Installer")
st.markdown("### Welcome to the ROCm Windows 11 Installation Wizard")

if st.button("Run System Compatibility Check"):
    with st.spinner("Checking system compatibility..."):
        results = run_hardware_check()
        st.code(results)

st.sidebar.markdown("""
## Installation Steps
1. System Compatibility Check
2. Driver Installation
3. Environment Setup
4. Validation
""")

# Installation progress tracking
if 'install_stage' not in st.session_state:
    st.session_state.install_stage = 0

stages = ['Compatibility Check', 'Driver Installation', 'Environment Setup', 'Validation']
st.progress(st.session_state.install_stage / len(stages))