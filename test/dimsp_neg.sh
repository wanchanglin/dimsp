# wl-20-03-2019, Wed: Rscript test code for mzXML negative mode. 

Rscript --vanilla ../dimsp.R \
  --mzxml_file "../test-data/mzXML/030317_mouse_liver_cs16_neg_001.mzXML, ../test-data/mzXML/030317_mouse_liver_cs16_neg_004.mzXML" \
  --targ_file  "../test-data/LipidList_generator/Negative_LipidList.tsv" \
  --rt_low 80.0 \
  --rt_high 120.0 \
  --mz_low 185.0 \
  --mz_high 1200.0 \
  --sign_file "../test-data/res_dimsp/mzxml_neg_sign.tsv" \
  --devi TRUE \
  --devi_file "../test-data/res_dimsp/mzxml_neg_devi.tsv"\
  --indi TRUE \
  --indi_file "../test-data/res_dimsp/mzxml_neg_indi.xlsx"\
