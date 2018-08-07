# dimsp for Galaxy #

This is Galaxy tool for R tools `dims_processing` for data processing of
direct-infusion mass spectrometry-based lipidomics data.

For details, see [dims_processing](https://github.com/hallz/dims_processing). 

## Installation ##

You need to install [Galaxy](https://github.com/galaxyproject/galaxy) and
[R](https://cran.r-project.org/) under Linux. 

- Install four R packages `optparse`, `WriteXLS`, `xcms` and `data.table`
  inside R. 
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
    </section>

  </toolbox>
  ```

- Test data:
  - positive and negative DIMS files in mzXML are located in `test-data`.
  - Lipid lists in TSV(Tab Separated Values) format are in directory 
    `LipidList_generator`. 

## To-Do ##

- Dependencies will be handled by CONDA. This includes all R packages used.
- Any other issues

## Authors, contributors & contacts ##

- Wanchang Lin (wl361@cam.ac.uk), University of Cambridge 
- Zoe Hall (zlh22@cam.ac.uk), University of Cambridge 
- Julian L Griffin (jlg40@cam.ac.uk), University of Cambridge 

