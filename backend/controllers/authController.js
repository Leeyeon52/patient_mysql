// C:\Users\user\Desktop\v4\backend\controllers\authController.js
// 인증 관련 비즈니스 로직을 처리합니다.

const bcrypt = require('bcryptjs'); // 비밀번호 해싱을 위한 라이브러리
const jwt = require('jsonwebtoken'); // JWT(JSON Web Token) 생성을 위한 라이브러리

// 사용자 등록 함수
exports.registerUser = async (req, res) => {
    const { username, password, email } = req.body;
    const pool = req.pool; // server.js에서 전달받은 DB 풀

    if (!username || !password || !email) {
        return res.status(400).json({ message: '모든 필드를 입력해주세요.' });
    }

    try {
        // 비밀번호 해싱
        const hashedPassword = await bcrypt.hash(password, 10); // 솔트 라운드 10

        // 사용자 정보를 데이터베이스에 삽입
        const [result] = await pool.execute(
            'INSERT INTO users (username, password_hash, email) VALUES (?, ?, ?)',
            [username, hashedPassword, email]
        );

        res.status(201).json({ message: '회원가입이 성공적으로 완료되었습니다.', userId: result.insertId });
    } catch (error) {
        console.error('회원가입 오류:', error);
        // 사용자 이름 또는 이메일 중복 오류 처리
        if (error.code === 'ER_DUP_ENTRY') {
            return res.status(409).json({ message: '이미 존재하는 사용자 이름 또는 이메일입니다.' });
        }
        res.status(500).json({ message: '서버 오류가 발생했습니다.' });
    }
};

// 사용자 로그인 함수
exports.loginUser = async (req, res) => {
    const { username, password } = req.body;
    const pool = req.pool;

    if (!username || !password) {
        return res.status(400).json({ message: '사용자 이름과 비밀번호를 입력해주세요.' });
    }

    try {
        // 데이터베이스에서 사용자 찾기
        const [rows] = await pool.execute('SELECT * FROM users WHERE username = ?', [username]);

        if (rows.length === 0) {
            return res.status(401).json({ message: '잘못된 사용자 이름 또는 비밀번호입니다.' });
        }

        const user = rows[0];

        // 비밀번호 비교
        const isMatch = await bcrypt.compare(password, user.password_hash);

        if (!isMatch) {
            return res.status(401).json({ message: '잘못된 사용자 이름 또는 비밀번호입니다.' });
        }

        // JWT 토큰 생성
        const token = jwt.sign(
            { id: user.id, username: user.username },
            process.env.JWT_SECRET, // .env 파일에 정의된 비밀 키 사용
            { expiresIn: '1h' } // 토큰 유효 기간 1시간
        );

        res.status(200).json({ message: '로그인 성공', token, userId: user.id, username: user.username });
    } catch (error) {
        console.error('로그인 오류:', error);
        res.status(500).json({ message: '서버 오류가 발생했습니다.' });
    }
};

// 아이디 중복 체크 함수
exports.checkUsernameAvailability = async (req, res) => {
    const { username } = req.query; // 쿼리 파라미터로 username을 받습니다.
    const pool = req.pool;

    // ✅ 디버그 로그 추가: Flutter 앱에서 어떤 username 값이 넘어오는지 확인
    console.log(`[DEBUG] checkUsernameAvailability: Received username -> "${username}"`);

    if (!username) {
        // ✅ username이 없는 경우에도 로그를 남겨서 확인
        console.log('[DEBUG] checkUsernameAvailability: Username is empty or null.');
        return res.status(400).json({ message: '사용자 이름을 입력해주세요.' });
    }

    try {
        const [rows] = await pool.execute('SELECT id FROM users WHERE username = ?', [username]);
        // ✅ 디버그 로그 추가: 데이터베이스 쿼리 결과 확인
        console.log(`[DEBUG] checkUsernameAvailability: Query result rows.length -> ${rows.length}`);
        console.log('[DEBUG] checkUsernameAvailability: Query result rows ->', rows);

        if (rows.length > 0) {
            // 이미 존재하는 사용자 이름
            console.log(`[DEBUG] checkUsernameAvailability: Username "${username}" is already in use.`);
            res.status(200).json({ available: false, message: '이미 사용 중인 아이디입니다.' });
        } else {
            // 사용 가능한 사용자 이름
            console.log(`[DEBUG] checkUsernameAvailability: Username "${username}" is available.`);
            res.status(200).json({ available: true, message: '사용 가능한 아이디입니다.' });
        }
    } catch (error) {
        console.error('아이디 중복 체크 오류:', error);
        res.status(500).json({ message: '서버 오류가 발생했습니다.' });
    }
};
