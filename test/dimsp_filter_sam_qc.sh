# wl-08-08-2018, Tue: Rscript test code for Linux. 
# wl-20-03-2019, Wed: To_Do: need to debug when mv=T
# wl-29-03-2019, Fri: make mv filtering on sample inside qc filtering
#  otherwise no output for 'filter_file' (should increase 'qc_rsd_thres')
# wl-01-04-2019, Mon: the threshold of RSD is crucial. Increase it if
#  neccessary.

Rscript --vanilla ../dimsp_filter.R \
  --peak_file "../test-data/pos_peak.tsv" \
  --grp_file_sel "yes" \
  --grp_file  "../test-data/grp_sam_qc.tsv" \
  --qc T \
  --qc_rsd_thres "60.0" \
  --qc_mv_qc_sam T \
  --bl F \
  --mv F \
  --merge T \
  --pdf_file "../test-data/res/sam_qc_hist_box.pdf"\
  --filter_file "../test-data/res/sam_qc_peak_filter.tsv"\
