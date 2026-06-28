async function test() {
    try {
        const loginRes = await fetch('http://localhost:5109/api/Auth/login', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                email: "tuilabo2018@gmail.com",
                password: "Password123!"
            })
        });
        const loginData = await loginRes.json();
        console.log(loginData);
    } catch (e) {
        console.log(e.message);
    }
}
test();
