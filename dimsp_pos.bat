rem wl-07-08-2018, Tue: Rscript test code for Windows. 

Rscript --vanilla dimsp.R ^
  --mzxml_file "./test-data/DIMS_pos/030317_mouse_liver_cs16_pos_001.mzXML, ./test-data/DIMS_pos/030317_mouse_liver_cs16_pos_002.mzXML, ./test-data/DIMS_pos/030317_mouse_liver_cs16_pos_003.mzXML, ./test-data/DIMS_pos/030317_mouse_liver_cs16_pos_004.mzXML" ^
  --targ_file  "./LipidList_generator/Positive_LipidList.tsv" ^
  --sign_file "pos_sign.tsv" ^
  --devi TRUE ^
  --devi_file "pos_devi.tsv"^
  --indi TRUE ^
  --indi_file "pos_indi.xlsx"^
