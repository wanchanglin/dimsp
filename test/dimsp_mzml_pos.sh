# wl-20-03-2019, Wed: mzML file test. (positive) 
# wl-06-10-2019, Sun: use reduced data set done by Melanie Föll
#  (melanie.foell@mol-med.uni-freiburg.de)

  # --rt_low 30.0 \
  # --rt_high 35.0 \
  # --mz_low 800.0 \
  # --mz_high 1000.0 \

Rscript --vanilla ../dimsp.R \
  --mzxml_file "../test-data/mzML/01_sample.mzML, ../test-data/mzML/02_sample.mzML,../test-data/mzML/03_sample.mzML,../test-data/mzML/04_sample.mzML" \
  --targ_file  "../test-data/lipid_list/Positive_LipidList.tsv" \
  --rt_low 20.0 \
  --rt_high 60.0 \
  --mz_low 200.0 \
  --mz_high 1200.0 \
  --hwidth 0.01 \
  --devi TRUE \
  --indi TRUE \
  --sign_file "../test-data/res/mzml_pos_sign.tsv" \
  --devi_file "../test-data/res/mzml_pos_devi.tsv" \
  --indi_file "../test-data/res/mzml_pos_indi.tsv" \
