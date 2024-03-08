const js2xmlparser = require('js2xmlparser');

function jsonToXml(jsonData, rootElement = 'root') {
    return js2xmlparser.parse(rootElement, jsonData);
}

function respond(req, res, data, status = 200) {
    if (req.headers.accept === 'application/xml') {
        res.set('Content-Type', 'application/xml');
        res.status(status).send(jsonToXml(data));
        return;
    }

    res.status(status).json(data);
}

module.exports = respond;
