# wl-08-08-2018, Tue: Rscript test code for Linux. 

Rscript --vanilla ../dimsp_filter.R \
  --peak_file "../test-data/pos_peak.tsv" \
  --grp_file_sel "yes" \
  --grp_file  "../test-data/grp_sam_qc_bl.tsv" \
  --qc T \
  --qc_mv_qc_sam T \
  --bl T \
  --mv F \
  --merge F \
  --mv_impute "knn" \
  --pdf_file "../test-data/res_dimsp_filter/sam_qc_bl_hist_box.pdf"\
  --filter_file "../test-data/res_dimsp_filter/sam_qc_bl_peak_filter.tsv"\
