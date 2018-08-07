# massPix for Galaxy #

This is Galaxy tool for R tools `dims_processing` for data processing of
direct-infusion mass spectrometry-based lipidomics data.

For details, see [dims_processing](https://github.com/hallz/dims_processing). 

## Installation ##

You need to install [Galaxy](https://github.com/galaxyproject/galaxy) and
[R](https://cran.r-project.org/) under Linux. 

- Install four R packages `optparse`, `WriteXLS`, `calibrate` and `rJava`
  inside R. 
- Do not install R package `massPix`. This tool embeds a modified `massPix`
  package for Galaxy only.
- Use `git` to clone this tool

  ```bash
  git clone https://github.com/wanchanglin/massPix.git
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
      <tool file="/path/to/massPix/massPix.xml" />
    </section>

  </toolbox>
  ```

- Download test data (.ibd and .imzML files) from the
  [MetaboLights](https://www.ebi.ac.uk/metabolights/) repository accession
  number [MTBLS487](https://www.ebi.ac.uk/metabolights/MTBLS487). 

## To-Do ##

- Dependencies will be handled by CONDA. This includes all R packages used.
- Any other issues

## Authors, contributors & contacts ##

- Wanchang Lin (wl361@cam.ac.uk), University of Cambridge 
- Zoe Hall (zlh22@cam.ac.uk), University of Cambridge 
- Julian L Griffin (jlg40@cam.ac.uk), University of Cambridge 

