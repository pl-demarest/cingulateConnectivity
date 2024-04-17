
rightACC = {'G_and_S_cingul-Ant','G_and_S_cingul-Mid-Ant','G_and_S_cingul-Mid-Post'};
leftACC = {'ctx_lh_G_and_S_cingul-Ant','wm_lh_G_and_S_cingul-Ant'};

rightMCC = {'ctx_rh_G_and_S_cingul-Mid-Ant','ctx_rh__and_S_cingul-Mid-Ant','wm_rh_G_and_S_cingul-Mid-Ant','wm_rh_G_and_S_cingul-Mid-Post'};
leftMCC = {'ctx_lh_G_and_S_cingul-Mid-Ant','ctx_lh_G_and_S_cingul-Mid-Post','wm_lh_G_and_S_cingul-Mid-Ant','wm_lh_G_and_S_cingul-Mid-Post'};

rightPCC = {'ctx_rh_G_cingul-Post-dorsal', 'ctx_rh_G_cingul-Post-ventral','wm_rh_G_cingul-Post-dorsal','wm_rh_G_cingul-Post-ventral',};
leftPCC = {'ctx_lh_G_cingul-Post-dorsal','ctx_lh_G_cingul-Post-ventral','wm_lh_G_cingul-Post-dorsal','wm_lh_G_cingul-Post-ventral'};

load('/Users/phildemarest/Library/CloudStorage/Box-Box/BJH034/VERA_BJH034/brain.mat')
[subAnnotation, subsetCortex] = get3DSubsets(rightACC,data.VERA.cortex, data.VERA.annotation);
figure;
plot3DModel(gca,subsetCortex,subAnnotation);