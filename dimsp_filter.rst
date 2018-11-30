---------------
DIMPS Filtering
---------------

Description
-----------

This tool performs filtering on the DIMS peaks produced by
'dims-processing'. Current three methods are implemented:

QC filtering
  Filtering based on the RSD of QC samples. The peaks with RSD larger than
  the designated threshold will be removed. Also missing value (MV)
  filtering can be applied to 'qc' or 'sample'.

Blank filtering
  Filtering based on the characteristics of blank samples. The peaks whose
  characteristics in 'sample' is less than in 'blank' will be removed. An
  option of MV filtering on 'sample' can be employed.

MV filtering
  Filtering based on the missing value percentages. The peaks with the
  percentages larger than the designated threshold will be removed. The
  operation is performed on 'sample'. If MV filtering is not performed on
  'sample' inside 'QC filtering' and 'Blank filtering', this procedure
  should be employed. Without MV filtering, even 'MV imputation' will fail
  in some cases.


