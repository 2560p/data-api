import postgres from 'postgres';

const config = {
    host: process.env.db_host,
    port: process.env.db_port,
    username: process.env.db_username,
    password: process.env.db_password,
    db: process.env.db_dbname,
};

const sql = postgres(
    `postgres://${config.username}:${config.password}@${config.host}:${config.port}/${config.db}`
);

function parse_tuple(str) {
    const values = str.slice(1, -1).split(',');
    const tuple = values.map((value) => String(value.trim()));
    return tuple;
}

// users auth
async function register_user(email, password) {
    let status = await sql`select public.user_register(${email}, ${password})`;

    status = parse_tuple(status[0]['user_register']);
    if (Number(status[0]) === -1) {
        return [false, null];
    }

    return [true, status[1]];
}

async function retrieve_password_hash_user(email) {
    let status = await sql`select public.user_retrieve_password_hash(${email})`;

    status = parse_tuple(status[0]['user_retrieve_password_hash']);
    if (Number(status[0]) === -1) {
        return [false, null, null];
    }

    return [true, status[0], status[1]];
}

// admin auth
async function register_admin(email, password, role) {
    let status =
        await sql`select public.admin_register(${email}, ${password}, ${role}::public.role_type)`;

    status = parse_tuple(status[0]['admin_register']);
    if (Number(status[0]) === -1) {
        return [false, null];
    }

    return [true, status[1]];
}

async function retrieve_password_hash_admin(email) {
    let status =
        await sql`select public.admin_retrieve_password_hash(${email})`;

    status = parse_tuple(status[0]['admin_retrieve_password_hash']);
    if (Number(status[0]) === -1) {
        return [false, null, null];
    }

    return [true, status[0], status[1]];
}

// refresh token
async function update_refresh_token(admin_id, token) {
    // the expiration is in 3 days
    let expiration = new Date();
    expiration.setDate(expiration.getDate() + 3);

    await sql`delete from refresh_tokens where admin_id = ${admin_id}`;
    await sql`insert into refresh_tokens values (${admin_id}, ${token}, ${expiration})`;
}

async function retrieve_admin_by_refresh_token(token) {
    let status = await sql`select * from refresh_tokens where token = ${token}`;

    if (status.length === 0) {
        return [false, null];
    }

    status = status[0];

    // whenever the database updates the expiration date,
    // it sets the date in UTC.
    // so we need to adjust the current date to UTC.
    let now = new Date();
    let utc = new Date(now.getTime() + now.getTimezoneOffset() * 60000);

    if (utc > status['expires_at']) {
        await remove_refresh_token(status['admin_id']);
        return [false, null];
    }

    return [true, status['admin_id']];
}

async function remove_refresh_token(admin_id) {
    await sql`delete from refresh_tokens where admin_id = ${admin_id}`;
}

// exports
export {
    sql,
    register_user,
    retrieve_password_hash_user,
    register_admin,
    retrieve_password_hash_admin,
    update_refresh_token,
    retrieve_admin_by_refresh_token,
    remove_refresh_token,
};
