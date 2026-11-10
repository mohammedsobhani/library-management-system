import 'dotenv/config';
import app from './app';

const port = Number(process.env.PORT) || 10000;

app.listen(port, () => {
  console.log(`Backend server listening on port ${port}`);
});