# wl-20-03-2019, Wed: mzML file test. (positive) 

Rscript --vanilla ../dimsp.R \
  --mzxml_file "../test-data/mzML/01_sample.mzML, ../test-data/mzML/02_sample.mzML,../test-data/mzML/03_sample.mzML,../test-data/mzML/04_sample.mzML" \
  --targ_file  "../test-data/LipidList_generator/Positive_LipidList.tsv" \
  --rt_low 20.0 \
  --rt_high 60.0 \
  --mz_low 200.0 \
  --mz_high 1200.0 \
  --hwidth 0.01 \
  --sign_file "../test-data/res_dimsp/mzml_pos_sign.tsv" \
  --devi TRUE \
  --devi_file "../test-data/res_dimsp/mzml_pos_devi.tsv"\
  --indi TRUE \
  --indi_file "../test-data/res_dimsp/mzml_pos_indi.xlsx"\
