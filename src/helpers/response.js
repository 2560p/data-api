const { js2xml } = require('xml-js');

function jsonToXml(jsonData) {
    return js2xml(jsonData, {
        compact: true,
        ignoreComment: true,
        spaces: 4,
    });
}

function respond(req, res, data, xml_root = null, status = 200) {
    if (req.headers.accept === 'application/xml') {
        res.set('Content-Type', 'application/xml');
        data = xml_root ? { [xml_root]: data } : data;
        res.status(status).send(jsonToXml(data));
        return;
    }

    res.status(status).json(data);
}

module.exports = respond;
