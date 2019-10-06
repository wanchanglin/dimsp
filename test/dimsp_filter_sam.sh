# wl-08-08-2018, Tue: Rscript test code for Linux. 

Rscript --vanilla ../dimsp_filter.R \
  --peak_file "../test-data/pos_peak.tsv" \
  --grp_file_sel "yes" \
  --grp_file  "../test-data/grp_sam.tsv" \
  --qc F \
  --bl F \
  --mv F \
  --merge T \
  --pdf_file "../test-data/res/sam_hist_box.pdf"\
  --filter_file "../test-data/res/sam_peak_filter.tsv"\
