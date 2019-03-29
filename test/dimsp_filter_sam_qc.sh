# wl-08-08-2018, Tue: Rscript test code for Linux. 
# wl-20-03-2019, Wed: To_Do: need to debug when mv=T
# wl-29-03-2019, Fri: make mv filtering on sample inside qc filtering
#  otherwise no output for 'filter_file'

Rscript --vanilla ../dimsp_filter.R \
  --peak_file "../test-data/pos_peak.tsv" \
  --grp_file_sel "yes" \
  --grp_file  "../test-data/grp_sam_qc.tsv" \
  --qc T \
  --qc_mv_qc_sam F \
  --bl F \
  --mv F \
  --merge T \
  --pdf_file "../test-data/res_dimsp_filter/sam_qc_hist_box.pdf"\
  --filter_file "../test-data/res_dimsp_filter/sam_qc_peak_filter.tsv"\
