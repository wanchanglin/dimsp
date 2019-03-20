rem wl-07-08-2018, Tue: Rscript test code for Windows. 

Rscript --vanilla ../dimsp.R ^
  --mzxml_file  "../test-data/mzXML/030317_mouse_liver_cs16_pos_001.mzXML, ../test-data/mzXML/030317_mouse_liver_cs16_pos_002.mzXML" ^
  --targ_file  "../test-data/LipidList_generator/Positive_LipidList.tsv" ^
  --sign_file "../test-data/res_dimsp/mzxml_pos_sign.tsv" ^
  --devi TRUE ^
  --devi_file "../test-data/res_dimsp/mzxml_pos_devi.tsv"^
  --indi TRUE ^
  --indi_file "../test-data/res_dimsp/mzxml_pos_indi.xlsx"^
