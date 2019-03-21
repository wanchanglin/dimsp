# wl-21-03-2019, Thu: Rscript test code for input group. 

Rscript --vanilla ../dimsp_filter.R \
  --peak_file "../test-data/pos_peak.tsv" \
  --grp_file_sel "no" \
  --groups  "Sample,sample, samplE, sample, sample, sample, sample, sample, sample, sample, qc, qc, blank, blank" \
  --qc_rsd_thres 60.0 \
  --mv T \
  --merge F \
  --mv_impute "mean" \
  --pdf_file "../test-data/res_dimsp_filter/sam_qc_bl_hist_box_1.pdf"\
  --filter_file "../test-data/res_dimsp_filter/sam_qc_bl_peak_filter_1.tsv"\
