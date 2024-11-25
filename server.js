const express = require('express');
const mongoose = require('mongoose');
 
const app = express();
const port = 3000;
 
// Middleware
app.use(express.json());
 
// MongoDB Connection
mongoose.connect('mongodb://mongo:27017/myapp', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
});
const db = mongoose.connection;
 
db.on('error', console.error.bind(console, 'MongoDB connection error:'));
db.once('open', () => {
  console.log('Connected to MongoDB');
});
 
// Simple Model
const ItemSchema = new mongoose.Schema({ name: String });
const Item = mongoose.model('Item', ItemSchema);
 
// Routes
app.get('/', (req, res) => res.send('Hello, world!'));
app.post('/items', async (req, res) => {
  const newItem = new Item({ name: req.body.name });
  await newItem.save();
  res.json(newItem);
});
 
app.get('/items', async (req, res) => {
  const items = await Item.find();
  res.json(items);
});
 
// Start server
app.listen(port, () => console.log(`App running on http://localhost:${port}`));
 