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
    if (Number(status[0]) == -1) {
        return [false, null];
    }

    return [true, status[1]];
}

async function retrieve_password_hash_user(email) {
    let status = await sql`select public.user_retrieve_password_hash(${email})`;

    status = parse_tuple(status[0]['user_retrieve_password_hash']);
    if (Number(status[0]) == -1) {
        return [false, null, null];
    }

    return [true, status[0], status[1]];
}

// admin auth
async function register_admin(email, password, role) {
    let status =
        await sql`select public.admin_register(${email}, ${password}, ${role}::public.role_type)`;

    status = parse_tuple(status[0]['admin_register']);
    if (Number(status[0]) == -1) {
        return [false, null];
    }

    return [true, status[1]];
}

async function retrieve_password_hash_admin(email) {
    let status =
        await sql`select public.admin_retrieve_password_hash(${email})`;

    status = parse_tuple(status[0]['admin_retrieve_password_hash']);
    if (Number(status[0]) == -1) {
        return [false, null, null];
    }

    return [true, status[0], status[1]];
}

export {
    sql,
    register_user,
    retrieve_password_hash_user,
    register_admin,
    retrieve_password_hash_admin,
};
