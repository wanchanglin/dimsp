# wl-08-08-2018, Tue: Rscript test code for Linux. 

Rscript --vanilla dimsp_filter.R \
  --peak_file "./res/pos_peak.tsv" \
  --grp_file_sel "yes" \
  --grp_file  "./res/grp_sam_qc.tsv" \
  --qc_rsd_thres 60.0 \
  --mv T \
  --merge F \
  --mv_impute "mean" \
  --pdf_file "./res/hist_box.pdf"\
  --filter_file "./res/peak_filter.tsv"\
