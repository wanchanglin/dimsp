# wl-08-08-2018, Tue: Rscript test code for Linux. 

Rscript --vanilla ../dimsp_filter.R \
  --peak_file "../test-data/pos_peak.tsv" \
  --grp_file_sel "yes" \
  --grp_file  "../test-data/grp_sam_bl.tsv" \
  --qc F \
  --bl T \
  --mv F \
  --merge F \
  --pdf_file "../test-data/res/sam_bl_hist_box.pdf"\
  --filter_file "../test-data/res/sam_bl_peak_filter.tsv"\
