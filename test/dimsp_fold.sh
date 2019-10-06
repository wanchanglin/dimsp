# wl-20-03-2019, Wed: use all mzML files

Rscript --vanilla ../dimsp.R \
  --mzxml_file "../test-data/mzML" \
  --targ_file  "../test-data/LipidList_generator/Positive_LipidList.tsv" \
  --sign_file "../test-data/res/mzml_pos_sign.tsv" \
  --devi TRUE \
  --devi_file "../test-data/res/mzml_pos_devi.tsv"\
  --indi TRUE \
  --indi_file "../test-data/res/mzml_pos_indi.xlsx"\
