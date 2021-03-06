<!DOCTYPE html>
<html>
  <head>
    <title>He2Dec</title>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <script language="javascript" type="text/javascript">
      var num = {
        hex2dec : function(n) {
          return Number(n) ? Number(n) : 'Wrong data type';
        },

        dec2hex : function(n) {
          return Number(n) ? '0x' + Number(n).toString(16).toUpperCase() : 'Wrong data type';
        },

        parseData : function(n) {
          if (n.slice(0, 2) == '0x') return this.hex2dec(n);
          else if (n.slice(0, 1) == 'x') return this.hex2dec('0' + n);
          else return this.dec2hex(n);
        }
      };

      function onClick() {
        document.getElementById('out').value =
          num.parseData(document.getElementById('in').value);
      }
    </script>
    <style type="text/css">
      body   { font-family: tahoma, sans-serif; }
      h1, h5 { color: #000080; margin-bottom: 0; }
      h3     { color: #9933cc; margin-top: 0; padding-top: 0; }
      h1     { font-size: 370%; }
      h5     { font-size: 65%; }
      p      { font-size: 80%; }
    </style>
  </head>
  <body>
    <center>
      <h1>Hex2Dec</h1>
      <h3>Converts hex to decimal and vice versa</h3>
      <p>Note that you should strongly input hex numbers with '0x' or 'x' prefixes.</p>
      <p>Input:&nbsp;&nbsp;&nbsp;<input type="textbox" id="in" /></p>
      <p>Output:&nbsp;<input type="textbox" id="out" /></p>
      <input type="button" value="Convert" onclick="onClick();" />
      <br />
      <h5>Copyright (C) 2010-2013 greg zakharov gregzakh@gmail.com</h5>
    </center>
  </body>
</html>
