# wl-08-08-2018, Tue: Rscript test code for Linux. 

Rscript --vanilla ../dimsp_filter.R \
  --peak_file "../test-data/pos_peak.tsv" \
  --grp_file_sel "yes" \
  --grp_file  "../test-data/grp_sam.tsv" \
  --qc F \
  --bl F \
  --mv T \
  --merge F \
  --pdf_file "../test-data/res_dimsp_filter/sam_hist_box.pdf"\
  --filter_file "../test-data/res_dimsp_filter/sam_peak_filter.tsv"\
