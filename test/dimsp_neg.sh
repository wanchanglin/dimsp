# wl-08-08-2018, Tue: Rscript test code for Linux. 

Rscript --vanilla ../dimsp.R \
  --mzxml_file "../test-data/DIMS_neg/030317_mouse_liver_cs16_neg_001.mzXML, ../test-data/DIMS_neg/030317_mouse_liver_cs16_neg_004.mzXML" \
  --targ_file  "../LipidList_generator/Negative_LipidList.tsv" \
  --rt_low 80.0 \
  --rt_high 120.0 \
  --mz_low 185.0 \
  --mz_high 1200.0 \
  --sign_file "../res/neg_sign.tsv" \
  --devi TRUE \
  --devi_file "../res/neg_devi.tsv"\
  --indi TRUE \
  --indi_file "../res/neg_indi.xlsx"\
