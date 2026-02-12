const fallbackProducts = [
  { id: 1, name: 'Bananas', category: 'produce', customer_price: 1.99, description: 'Fresh yellow bananas, 1 lb.' },
  { id: 2, name: 'Avocados', category: 'produce', customer_price: 3.49, description: 'Hass avocados, pack of 4.' },
  { id: 3, name: 'Sourdough Bread', category: 'bakery', customer_price: 4.2, description: 'Baked this morning.' },
  { id: 4, name: 'Croissants', category: 'bakery', customer_price: 5.5, description: 'Buttery french-style croissants.' },
  { id: 5, name: 'Whole Milk', category: 'dairy', customer_price: 3.15, description: '1 gallon, vitamin D.' },
  { id: 6, name: 'Greek Yogurt', category: 'dairy', customer_price: 4.45, description: 'Plain yogurt, 32oz tub.' },
];

let products = [...fallbackProducts];
let activeFilter = 'all';
let cart = JSON.parse(localStorage.getItem('freshcart_cart') || '[]');

const grid = document.getElementById('productGrid');
const cartDrawer = document.getElementById('cartDrawer');
const cartCount = document.getElementById('cartCount');
const cartItems = document.getElementById('cartItems');
const cartTotal = document.getElementById('cartTotal');

function fmt(value) {
  return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(value);
}

function renderProducts() {
  const visible = activeFilter === 'all' ? products : products.filter((p) => p.category === activeFilter);

  if (!visible.length) {
    grid.innerHTML = '<p class="muted">No products in this category right now.</p>';
    return;
  }

  grid.innerHTML = visible
    .map(
      (p) => `
      <article class="product">
        <span class="tag">${p.category || 'grocery'}</span>
        <h4>${p.name}</h4>
        <p>${p.description || 'No description available.'}</p>
        <footer>
          <strong>${fmt(p.customer_price)}</strong>
          <button class="btn-secondary" data-add="${p.id}">Add</button>
        </footer>
      </article>
    `,
    )
    .join('');
}

function saveCart() {
  localStorage.setItem('freshcart_cart', JSON.stringify(cart));
}

function renderCart() {
  if (!cart.length) {
    cartItems.innerHTML = '<p class="muted">Your cart is empty.</p>';
    cartTotal.textContent = fmt(0);
    cartCount.textContent = '0';
    return;
  }

  cartItems.innerHTML = cart
    .map(
      (item) => `
        <div class="cart-row">
          <div>
            <strong>${item.name}</strong>
            <p class="muted">Qty ${item.qty}</p>
          </div>
          <strong>${fmt(item.qty * item.price)}</strong>
        </div>
      `,
    )
    .join('');

  const totalQty = cart.reduce((sum, item) => sum + item.qty, 0);
  const totalAmount = cart.reduce((sum, item) => sum + item.qty * item.price, 0);
  cartCount.textContent = String(totalQty);
  cartTotal.textContent = fmt(totalAmount);
}

function addToCart(id) {
  const product = products.find((p) => p.id === id);
  if (!product) return;

  const existing = cart.find((i) => i.id === id);
  if (existing) existing.qty += 1;
  else cart.push({ id: product.id, name: product.name, qty: 1, price: product.customer_price });

  saveCart();
  renderCart();
}

async function loadProductsFromApi() {
  try {
    const res = await fetch('/products/?limit=30');
    if (!res.ok) throw new Error('Failed API request');
    const apiProducts = await res.json();
    if (!Array.isArray(apiProducts) || !apiProducts.length) return;

    products = apiProducts.map((item) => ({
      id: item.id,
      name: item.name,
      customer_price: item.customer_price,
      description: 'Freshly sourced and quality checked.',
      category: ['produce', 'bakery', 'dairy'][item.id % 3],
    }));
  } catch {
    products = [...fallbackProducts];
  } finally {
    renderProducts();
  }
}

document.querySelector('.filters').addEventListener('click', (event) => {
  const button = event.target.closest('button[data-filter]');
  if (!button) return;

  activeFilter = button.dataset.filter;
  document.querySelectorAll('.filters button').forEach((b) => b.classList.remove('active'));
  button.classList.add('active');
  renderProducts();
});

grid.addEventListener('click', (event) => {
  const button = event.target.closest('button[data-add]');
  if (!button) return;
  addToCart(Number(button.dataset.add));
});

document.getElementById('openCart').addEventListener('click', () => {
  cartDrawer.classList.add('open');
  cartDrawer.setAttribute('aria-hidden', 'false');
});

document.getElementById('closeCart').addEventListener('click', () => {
  cartDrawer.classList.remove('open');
  cartDrawer.setAttribute('aria-hidden', 'true');
});

renderCart();
loadProductsFromApi();
