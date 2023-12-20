module.exports = function () {
    const expected_envs = [
        'jwt_secret',
        'port',
        'db_root_password',
        'db_host',
        'db_port',
        'db_username',
        'db_password',
        'db_dbname',
        'admin_key',
    ];

    let is_valid = true;
    for (let i = 0; i < expected_envs.length; i++) {
        if (expected_envs[i] in process.env) {
            continue;
        }
        console.log(`Missing environment variable: ${expected_envs[i]}`);
        is_valid = false;
    }

    if (!is_valid) {
        process.exit(1);
    }
};
