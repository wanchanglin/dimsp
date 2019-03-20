# wl-08-08-2018, Tue: Rscript test code for Linux. 
# wl-20-03-2019, Wed: To_Do: need to debug when mv=T

Rscript --vanilla ../dimsp_filter.R \
  --peak_file "../test-data/pos_peak.tsv" \
  --grp_file_sel "yes" \
  --grp_file  "../test-data/grp_sam_qc.tsv" \
  --qc T \
  --bl F \
  --mv F \
  --merge F \
  --pdf_file "../test-data/res_dimsp_filter/sam_qc_hist_box.pdf"\
  --filter_file "../test-data/res_dimsp_filter/sam_qc_peak_filter.tsv"\
