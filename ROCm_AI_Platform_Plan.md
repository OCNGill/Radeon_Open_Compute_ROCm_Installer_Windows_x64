# ROCm Installer & AI Platform Evolution Plan

## Executive Summary
This plan outlines the transformation of the current ROCm Windows Installer into a comprehensive "One-Stop Shop" AI Development Platform. The goal is to not only install the drivers and base software but to also provision a complete, ready-to-use AI environment including Docker containers, vLLM servers, and local LLM management, leveraging the architecture and patterns from the Atlas CI/CD Auto-Fixer.

## 1. Current State Assessment

### ROCm Installer (`Radeon_Open_Compute_ROCm_Installer_Windows_x64`)
*   **Strengths:**
    *   Solid foundation for installing ROCm, WSL2, and PyTorch.
    *   Streamlit-based GUI for installation wizard.
    *   WiX-based MSI installer for distribution.
*   **Weaknesses:**
    *   GUI code has formatting/indentation issues (Fixed in this iteration).
    *   Limited to "installation" only; doesn't help with "day 2" operations (running models, serving APIs).
    *   No built-in container management.

### Atlas CI/CD Auto-Fixer (`atlas-ci-cd-auto-fixer`)
*   **Strengths:**
    *   Advanced Streamlit GUI with "Robot Thoughts" and complex workflow management.
    *   Robust LLM configuration management (`llm_config.yaml`).
    *   Agentic workflow (Propose -> Verify -> Apply).
    *   Integration with Ollama and other model providers.
*   **Relevance:**
    *   The **Model Management** and **Configuration** patterns can be directly ported.
    *   The **Agentic** approach can be used for "Self-Healing" the installation (e.g., if ROCm breaks, the agent fixes it).

## 2. Vision: The "One-Stop Shop" AI Platform

The new application will serve three distinct phases of the user journey:
1.  **Setup (The Installer):** Get drivers, WSL2, and Docker running.
2.  **Provision (The Builder):** Create optimized Docker containers for vLLM, PyTorch, etc.
3.  **Operate (The Dashboard):** Manage models, start/stop servers, and chat with local LLMs.

## 3. Action Plan

### Phase 1: Fix & Stabilize (Immediate)
*   **Objective:** Ensure the current installer works flawlessly and looks professional.
*   **Actions:**
    *   ✅ **Fix GUI Code:** Correct indentation and syntax errors in `src/gui/streamlit_app.py`.
    *   ✅ **Improve UX:** Ensure text areas for logs are large enough (500px) and readable.
    *   **Consolidate Code:** Ensure all copies of `streamlit_app.py` (in `agent/`, `python_with_conda_env/`, etc.) are synchronized or removed if redundant.

### Phase 2: Docker & Containerization (Weeks 1-2)
*   **Objective:** Enable the user to run AI workloads in isolated, reproducible environments.
*   **Actions:**
    *   **Docker Desktop Integration:** Add a check/install step for Docker Desktop in the main installer.
    *   **Container Management Tab:** Add a new tab to the Streamlit GUI for "Containers".
    *   **Pre-built Recipes:** Include Dockerfiles/Compose files for:
        *   `vllm-rocm`: A dedicated vLLM server optimized for AMD.
        *   `pytorch-interactive`: A JupyterLab environment for development.
    *   **One-Click Launch:** Buttons to build and run these containers directly from the GUI.

### Phase 3: vLLM & Model Management (Weeks 2-3)
*   **Objective:** Make it easy to download and serve models.
*   **Actions:**
    *   **Port Atlas Config:** Adapt `atlas_core/config/llm_config.yaml` to store model preferences and server settings.
    *   **Model Manager:** Create a UI to browse (HuggingFace/Ollama) and download models to a shared volume.
    *   **vLLM Orchestrator:**
        *   UI to select a model and click "Start Server".
        *   Backend script to spin up the `vllm-rocm` container with the selected model mounted.
        *   Expose an OpenAI-compatible endpoint (e.g., `http://localhost:8000/v1`).

### Phase 4: The "Atlas" Integration (Weeks 3-4)
*   **Objective:** Add intelligence to the platform.
*   **Actions:**
    *   **Local Chat Interface:** Add a "Chat" tab that connects to the local vLLM server (using the Atlas chat UI patterns).
    *   **Self-Healing Agent:** Implement a background agent (like Atlas's `Janus`) that monitors system health (GPU temps, driver status) and suggests fixes.
    *   **Dev Tools:** Integrate the "Auto-Fixer" capabilities to help users debug their own PyTorch code running in the containers.

## 4. Technical Architecture

```mermaid
graph TD
    User[User] --> GUI[Streamlit Dashboard]
    GUI --> Installer[Installer Scripts (PowerShell)]
    GUI --> Docker[Docker Management]
    GUI --> Config[LLM Config (YAML)]
    
    Installer --> System[Windows System]
    System --> Drivers[AMD Drivers]
    System --> WSL2[WSL2 Ubuntu]
    
    Docker --> vLLM[vLLM Container]
    Docker --> Dev[Jupyter Container]
    
    vLLM --> Models[Model Storage (Shared Volume)]
    
    subgraph "Atlas Features"
        Agent[Self-Healing Agent]
        Chat[Local Chat UI]
    end
    
    GUI --> Agent
    GUI --> Chat
    Chat --> vLLM
```

## 5. Next Steps for You

1.  **Review the Fixes:** I have applied the fixes to `src/gui/streamlit_app.py`. Please verify the application runs without syntax errors.
2.  **Docker Prep:** Ensure Docker Desktop is installed on your dev machine to test the container integration.
3.  **Atlas Review:** Look at `temp_atlas_analysis/Atlas-GUI/app.py` to see how they handle the configuration loading and model selection. We will mimic this.

This plan moves beyond just "installing software" to "enabling capabilities," making your tool indispensable for AMD AI developers.
