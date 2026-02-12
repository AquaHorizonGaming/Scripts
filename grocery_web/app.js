const fallbackProducts = [
  { id: 1, name: 'Bananas', category: 'produce', customer_price: 1.99, description: 'Fresh yellow bananas, 1 lb.' },
  { id: 2, name: 'Avocados', category: 'produce', customer_price: 3.49, description: 'Hass avocados, pack of 4.' },
  { id: 3, name: 'Sourdough Bread', category: 'bakery', customer_price: 4.2, description: 'Baked this morning.' },
  { id: 4, name: 'Croissants', category: 'bakery', customer_price: 5.5, description: 'Buttery french-style croissants.' },
  { id: 5, name: 'Whole Milk', category: 'dairy', customer_price: 3.15, description: '1 gallon, vitamin D.' },
  { id: 6, name: 'Greek Yogurt', category: 'dairy', customer_price: 4.45, description: 'Plain yogurt, 32oz tub.' },
];

const sessionKey = 'freshcart_session';
const cartKey = 'freshcart_cart';
const sessionId = localStorage.getItem(sessionKey) || crypto.randomUUID();
localStorage.setItem(sessionKey, sessionId);

let products = [...fallbackProducts];
let activeFilter = 'all';
let cart = JSON.parse(localStorage.getItem(cartKey) || '[]');

const grid = document.getElementById('productGrid');
const cartDrawer = document.getElementById('cartDrawer');
const cartCount = document.getElementById('cartCount');
const cartItems = document.getElementById('cartItems');
const cartTotal = document.getElementById('cartTotal');
const toast = document.getElementById('toast');
const orderSection = document.getElementById('orderConfirmation');
const orderMeta = document.getElementById('orderMeta');
const orderItems = document.getElementById('orderItems');

function fmt(value) {
  return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(value);
}

function notify(message) {
  toast.textContent = message;
  toast.classList.remove('hidden');
  setTimeout(() => toast.classList.add('hidden'), 2000);
}

async function api(path, options = {}) {
  const response = await fetch(path, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      'X-Session-Id': sessionId,
      ...(options.headers || {}),
    },
  });

  const json = await response.json().catch(() => ({}));
  if (!response.ok) throw new Error(json.detail || 'Request failed');
  return json;
}

function persistCart(items) {
  cart = items;
  localStorage.setItem(cartKey, JSON.stringify(items));
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
          <div class="cart-row-top">
            <strong>${item.name}</strong>
            <strong>${fmt(item.quantity * item.unit_price)}</strong>
          </div>
          <div class="qty-controls">
            <button data-dec="${item.product_id}">-</button>
            <span>Qty ${item.quantity}</span>
            <button data-inc="${item.product_id}">+</button>
            <button class="remove-link" data-remove="${item.product_id}">Remove</button>
          </div>
        </div>
      `,
    )
    .join('');

  const totalQty = cart.reduce((sum, item) => sum + item.quantity, 0);
  const totalAmount = cart.reduce((sum, item) => sum + item.quantity * item.unit_price, 0);
  cartCount.textContent = String(totalQty);
  cartTotal.textContent = fmt(totalAmount);
}

async function syncCartFromApi() {
  try {
    const data = await api('/cart');
    persistCart(data.items || []);
    renderCart();
  } catch (error) {
    notify(error.message);
  }
}

async function addToCart(productId) {
  const product = products.find((p) => p.id === productId);
  if (!product) return;

  try {
    const data = await api('/cart/add', {
      method: 'POST',
      body: JSON.stringify({
        product_id: product.id,
        name: product.name,
        unit_price: product.customer_price,
        quantity: 1,
      }),
    });
    persistCart(data.items);
    renderCart();
    notify('Added to cart');
  } catch (error) {
    notify(error.message);
  }
}

async function updateQty(productId, qty) {
  try {
    const data = await api('/cart/update', {
      method: 'PUT',
      body: JSON.stringify({ product_id: productId, quantity: qty }),
    });
    persistCart(data.items);
    renderCart();
  } catch (error) {
    notify(error.message);
  }
}

async function removeItem(productId) {
  try {
    const data = await api('/cart/remove', {
      method: 'POST',
      body: JSON.stringify({ product_id: productId }),
    });
    persistCart(data.items);
    renderCart();
  } catch (error) {
    notify(error.message);
  }
}

function showOrderConfirmation(data) {
  orderMeta.textContent = `Order ID: ${data.order_id} • Status: ${data.status} • Total: ${fmt(data.total)}`;
  orderItems.innerHTML = data.items
    .map(
      (item) => `<div class="order-item-row"><span>${item.name} × ${item.quantity}</span><strong>${fmt(item.unit_price * item.quantity)}</strong></div>`,
    )
    .join('');

  orderSection.classList.remove('hidden');
  orderSection.scrollIntoView({ behavior: 'smooth' });
}

async function checkout() {
  if (!cart.length) {
    notify('Cart is empty');
    return;
  }

  try {
    const data = await api('/checkout', {
      method: 'POST',
      body: JSON.stringify({ items: cart }),
    });
    persistCart([]);
    renderCart();
    showOrderConfirmation(data);
    notify(data.message);
  } catch (error) {
    notify(error.message);
  }
}

async function loadProductsFromApi() {
  try {
    const apiProducts = await api('/products/');
    if (!Array.isArray(apiProducts) || !apiProducts.length) {
      renderProducts();
      return;
    }

    products = apiProducts.map((item) => ({
      id: item.id,
      name: item.name,
      customer_price: item.price_customer || 0,
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
  const addBtn = event.target.closest('button[data-add]');
  if (addBtn) {
    addToCart(Number(addBtn.dataset.add));
  }
});

cartItems.addEventListener('click', (event) => {
  const inc = event.target.closest('button[data-inc]');
  const dec = event.target.closest('button[data-dec]');
  const remove = event.target.closest('button[data-remove]');

  if (inc) {
    const id = Number(inc.dataset.inc);
    const item = cart.find((c) => c.product_id === id);
    if (item) updateQty(id, item.quantity + 1);
  }

  if (dec) {
    const id = Number(dec.dataset.dec);
    const item = cart.find((c) => c.product_id === id);
    if (item) updateQty(id, item.quantity - 1);
  }

  if (remove) {
    removeItem(Number(remove.dataset.remove));
  }
});

document.getElementById('openCart').addEventListener('click', () => {
  cartDrawer.classList.add('open');
  cartDrawer.setAttribute('aria-hidden', 'false');
});

document.getElementById('closeCart').addEventListener('click', () => {
  cartDrawer.classList.remove('open');
  cartDrawer.setAttribute('aria-hidden', 'true');
});

document.getElementById('checkoutBtn').addEventListener('click', checkout);

renderCart();
syncCartFromApi();
loadProductsFromApi();
