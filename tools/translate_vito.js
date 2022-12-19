const { create } = require("xmlbuilder2");
const translate = require("translate-google");
const xml2js = require("xml2js");
const fs = require("fs");
const builder = new xml2js.Builder();
const parser = new xml2js.Parser({
  explicitArray: true,
});
var filePath = "vito.xml";
fs.readFile(filePath, function (err, data) {
  parser.parseString(data, async function (err, result) {
    for await (const element of result.vito.commands[0].command) {
      console.log(element.description[0]);
      await translate(element.description[0], { from: "de", to: "en" })
        .then((res) => {
          console.log(res);
          element.description[0] = res;
        })
        .catch((err) => {
          console.error(err);
        });
    }
    console.log("Wrinting file...");

    let xml_string = builder.buildObject(result);
    fs.writeFile(filePath, xml_string, function (err, data) {
      if (err) console.log(err);
    });
  });
});
