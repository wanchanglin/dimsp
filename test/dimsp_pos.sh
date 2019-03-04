# wl-08-08-2018, Tue: Rscript test code for Linux. 
# wl-04-03-2019, Mon: 
#  - mz can be mzxml or mzml format
#  - mz file can be file path or full path file names in which each name is seperated by comma. for example:
#    --mzxml_file  "../test-data/DIMS_pos/030317_mouse_liver_cs16_pos_001.mzXML, ../test-data/DIMS_pos/030317_mouse_liver_cs16_pos_002.mzXML" \

Rscript --vanilla ../dimsp.R \
  --mzxml_file "../test-data/" \
  --targ_file  "../LipidList_generator/Positive_LipidList.tsv" \
  --sign_file "../res/pos_sign.tsv" \
  --devi TRUE \
  --devi_file "../res/pos_devi.tsv"\
  --indi TRUE \
  --indi_file "../res/pos_indi.xlsx"\
