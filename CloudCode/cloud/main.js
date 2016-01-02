//main.js
var fs = require('fs');
var layer = require('cloud/layer-parse-module/layer-module.js');
var layerProviderID = 'layer:///providers/05cbbee8-b10d-11e5-b2a6-2584730b1501';  // Should have the format of layer:///providers/<GUID>
var layerKeyID = 'layer:///keys/5821c3c6-b10e-11e5-b2a6-2584730b1501';   // Should have the format of layer:///keys/<GUID>
var privateKey = fs.readFileSync('cloud/layer-parse-module/keys/layer-key.js');
layer.initialize(layerProviderID, layerKeyID, privateKey);