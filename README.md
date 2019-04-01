# DIMSP for Galaxy #

Galaxy tool for Direct-Infusion Mass Spectrometry (DIMS) based lipidomics
data processing and filtering.

For details how to get annotation and peak table, see
[dims_processing](https://github.com/hallz/dims_processing). 

## Installation ##

- Install [Galaxy](https://github.com/galaxyproject/galaxy) under Linux.

- Install [conda](https://docs.conda.io/en/latest/miniconda.html) under
  Linux. `conda` is used to install `requirements` of this tool, i.e. R
  packages used: `optparse`, `WriteXLS`, `xcms`, `data.table`,
  `reshape`, `lattice`, `impute` and `pcaMethods`. 

- Use `git` to clone this tool

  ```bash
  git clone https://github.com/wanchanglin/dimsp.git
  ```

- Add this tool's location into Galaxy' tool config file:
  `~/Galaxy/config/tool_conf.xml`. For example, one simplified
  `tool_conf.xml` looks like:

  ```xml
  <?xml version='1.0' encoding='utf-8'?>
  <toolbox monitor="true">
    
    <section id="getext" name="Get Data">
      <tool file="data_source/upload.xml" />
    </section>
    
    <section id="MyTools" name="My Tools">
      <tool file="/path/to/dimsp/dimsp.xml" />
      <tool file="/path/to/dimsp/dimsp_filter.xml" />
    </section>

  </toolbox>
  ```

- Test data are in `test-data`, includes:
  - mzXML and mzML files for DIMSP processing.
  - Lipid lists in TSV(Tab Separated Values) format. 
  - TSV files for DIMSP filtering.

## Authors, contributors & contacts ##

- Wanchang Lin (wl361@cam.ac.uk), University of Cambridge 
- Zoe Hall (zlh22@cam.ac.uk), University of Cambridge 
- Julian L Griffin (jlg40@cam.ac.uk), University of Cambridge 

