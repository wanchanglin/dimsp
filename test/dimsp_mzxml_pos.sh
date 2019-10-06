# wl-08-08-2018, Tue: Rscript test code for Linux. 
# wl-04-03-2019, Mon: 
#  - mz can be mzxml or mzml format
#  - mz file can be file path or full path file names in which each name is
#    seperated by comma. for example:
# wl-20-03-2019, Wed: run this sheel script and save results inside
#   'test-data' for Galaxy planemo test comparison. 
Rscript --vanilla ../dimsp.R \
  --mzxml_file  "../test-data/mzXML/030317_mouse_liver_cs16_pos_001.mzXML, ../test-data/mzXML/030317_mouse_liver_cs16_pos_002.mzXML" \
  --targ_file  "../test-data/LipidList_generator/Positive_LipidList.tsv" \
  --indi TRUE \
  --devi TRUE \
  --sign_file "../test-data/res/mzxml_pos_sign.tsv" \
  --devi_file "../test-data/res/mzxml_pos_devi.tsv" \
  --indi_file "../test-data/res/mzxml_pos_indi.xlsx" \
