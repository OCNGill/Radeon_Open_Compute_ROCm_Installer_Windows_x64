# WiX Installer Development Roadmap

## Phase 1: Project Setup & Structure

### Day 1: Initialize WiX Project ? COMPLETE
- [x] Install WiX Toolset v3/v4 extension for VS 2022
- [x] Create new WiX Setup Project
- [x] Set up directory structure:
  ```
  installer/
  ??? Product.wxs    # Main installer definition
  ??? Components/
  ?   ??? Driver.wxs        # AMD driver component
  ? ??? ROCm.wxs# ROCm runtime component
  ?   ??? Python.wxs    # Python environment component
  ???? LLM_GUI.wxs       # LM Studio component
  ??? CustomActions/
  ?   ??? GPUDetection.ps1
  ?   ??? SecurityConfig.ps1
  ?   ??? Validation.ps1
  ??? Resources/
  ?   ??? Banner.png
  ???? Dialog.png
  ?   ??? License.rtf
  ??? Bundle.wxs       # Burn bundle definition
  ```

### Day 2: Core Installer Logic ? COMPLETE
- [x] Define Product element with upgrade logic
- [x] Create Feature hierarchy:
  - Core ROCm Runtime (required)
  - WSL2 Support (required)
  - PyTorch (required)
  - LM Studio (optional)
  - Advanced Tools (optional)
- [x] Implement custom actions:
  - Pre-install GPU detection
  - Driver version check
  - Security configuration
  - Post-install validation

### Day 3: Integration & Testing
- [ ] Integrate existing PowerShell scripts as custom actions
- [ ] Test install/uninstall on clean Windows 11 VM
- [ ] Verify rollback functionality

## Phase 2: Advanced Features (Days 4-7)

### Day 4: Security & Permissions
- [ ] Implement MS Defender Application Guard disable
- [ ] Implement Smart App Control disable
- [ ] Add UAC elevation handling
- [ ] Create restore point before changes

### Day 5: LLM GUI Integration
- [ ] Bundle LM Studio installer (or download link)
- [ ] Create post-install wizard for model selection
- [ ] Add desktop shortcuts and start menu items
- [ ] Documentation for first-run experience

### Day 6: CI/CD Pipeline
- [ ] Create GitHub Actions workflow
- [ ] Set up automated building
- [ ] Implement code signing
- [ ] Configure artifact publishing

### Day 7: Testing & Validation
- [ ] Test on RX 7900 XTX
- [ ] Test on RX 7800 XT
- [ ] Test on Ryzen AI systems
- [ ] Test upgrade scenarios
- [ ] Test uninstall cleanup

## Phase 3: Polish & Release (Days 8-10)

### Day 8: Documentation
- [ ] Update README with MSI instructions
- [ ] Create installation guide
- [ ] Add troubleshooting for MSI-specific issues
- [ ] Screenshot installer flow

### Day 9: Performance & Size Optimization
- [ ] Minimize MSI size (consider download vs bundle)
- [ ] Optimize custom action execution time
- [ ] Add progress indicators

### Day 10: Beta Release
- [ ] Create v0.1.0-beta tag
- [ ] Publish to GitHub releases
- [ ] Gather initial feedback
- [ ] Create feedback form

## Success Metrics

? **Must Have (MVP):**
- Single-click installation experience
- Automatic GPU detection and validation
- ROCm 6.1.3+ working with PyTorch
- LM Studio integration
- Clean uninstall

?? **Nice to Have (V1.1):**
- Offline installer option
- Multiple LLM GUI options
- Automatic driver updates
- Performance benchmarking

?? **Future (V2.0+):**
- ROCm 7.9.0 support
- RDNA 4 (RX 9070) support
- Docker integration
- Multi-GPU configuration
