# Read Pamgen Cube operator

##### Description

`read_pgcube` operator transforms a Pamgene Cube file (RData format) to Tercen datasets.

##### Usage

Input projection|.
---|---
`documentId`        | is the documentId (document can be a single Cube file, or a zipped set of Cube files)

Input parameters|.
---|---
`separateQT`   | Boolean parameter: if set, each quantitation type will have its own column (wide format). Otherwise the format will be long. Default value is true.

Output relations|.
---|---
`filename`          | character, the name of the Cube file

##### Details

The operator transforms Pamgene Cube files (RData format) into Tercen table. If the document is a ZIP file containing a set of Cube files, the operator extracts the Cube files and transforms them into Tercen table.
