const fs = require('fs').promises

function main(r) {
    let u = r.uri.split('/').filter(x=>x.length > 0)
    if ( u.length > 1 && METHODS[u[1]] ) {
        METHODS[u[1]](r)
    } else {
        r.return(200, JSON.stringify(r))
    }
}

const METHODS = {
    headers : r => r.return(200, JSON.stringify(r.headersIn)),
    ip      : r => r.return(200, r.remoteAddress),
    rdr     : r => r.return(301, r.args.url),
    ua      : r => r.return(200, r.headersIn['User-Agent']),
    body    : r => r.return(200, r.requestBuffer),
    version : r => r.return(200, JSON.stringify({ngx: r.variables.nginx_version, njs: njs.version, tz: process.env.TIMEZONE})),
    errorLog: r => fs.readFile('/opt/nginx/logs/error.log').then(data=>r.return(200, data)),
}

const run = () => {}

export default { main }
