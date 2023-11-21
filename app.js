import express from "express";
import { Router } from "express";
import users from "./src/users.js";

const router = Router();
router.use("/users", users);

const app = express();
const port = 8080;

app.use(router);

app.get("/", (req, res) => {
    res.send("Hello World!");
});

app.listen(port, () => {
    console.log(`Listening on port ${port}...`);
});
