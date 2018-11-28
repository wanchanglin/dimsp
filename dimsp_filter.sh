# wl-08-08-2018, Tue: Rscript test code for Linux. 

Rscript --vanilla dimsp_filter.R \
  --peak_file "./res/pos_peak.tsv" \
  --grp_file_sel T \
  --grp_file  "./res/grp_sam.tsv" \
  --qc_rsd_thres 60.0 \
  --mv T \
  --merge T \
  --mv_impute "pca" \
  --pdf_file "./res/hist_box.pdf"\
  --filter_file "./res/peak_ft.tsv"\
