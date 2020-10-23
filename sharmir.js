const primeNumber = 95971

function modulo(a, m) {
  result = a % m
  return result < 0 ? result + m : result
}

function modInverse(a, m) {
  [a, m] = [Number(a), Number(m)]
  
  if (Number.isNaN(a) || Number.isNaN(m)) {
    return NaNslice
  }

  a = (a % m + m) % m
  if (!a || m < 2) {
    return NaN
  }

  const s = []
  let b = m
  while(b) {
    [a, b] = [b, a % b]
    s.push({a, b})
  }
  if (a !== 1) {
    return NaN
  }

  let x = 1, y = 0
  for(let i = s.length - 2; i >= 0; --i) {
    [x, y] = [y,  x - y * Math.floor(s[i].a / s[i].b)]
  }
  return (y % m + m) % m
}

function getRandomInt() {
  return Math.floor(Math.random() * (95971 + 1))
}

function IsExistX(shares, N, x) {
  for(let i = 0 ; i < N ; i++) {
    if(shares[i][0] == x) {
      return true
    }
  }

  return false
}

function IsExistXfromK(shares, N, x, k) {
  for(let i = 0 ; i < N ; i++) {
    if(shares[i][2*k+0] == x) {
      return true
    }
  }
  return false
}

function create(message, K, N) {
  const messageBuffer = new Buffer.from(message)
  const secrets = [...messageBuffer]

  const slen = secrets.length
  const polynomials = new Array(slen)
  const shares = new Array(N)

  for(let i = 0; i<N ; i++) {
    shares[i] = new Array(2*slen)
  }

  for(let k = 0; k<slen ; k++) {

    polynomials[k] = new Array(K).fill(0)

    polynomials[k][0] = secrets[k]

    for(let i = 1; i < K ; i++) {
      polynomials[k][i] = getRandomInt()
    }

    for(let i = 0; i<N ; i++) {
      do {
        x=getRandomInt()
      } while(IsExistXfromK(shares, i, x, k))

      shares[i][2*k] = x
      shares[i][2*k+1] = evaludatePolynomial(polynomials[k], x)
    }

  }

  return shares
}

function evaludatePolynomial(polynomial, x) {  
  const last = polynomial.length - 1
  let result = polynomial[last]

  for (let i = last - 1; i >= 0; i--) {
      result = result * x
      result = result + polynomial[i]
      result = modulo(result, primeNumber)
  }

  return result
}

function combine(shares) {

  let slen = Math.floor(shares[0].length/2)
  var buffer = new Buffer.alloc(slen);

  for(let k=0 ; k<slen ; k++) {

    let secret = 0

    for(let i=0 ; i<shares.length ; i++) {

      const share = shares[i]
      const x = share[2*k]
      const y = share[2*k+1]

      let numerator = 1
      let denominator = 1

      for(let j=0 ; j<shares.length ; j++) {
        if( i != j ){
          numerator = numerator * -shares[j][2*k]
          numerator = modulo(numerator, primeNumber)

          denominator = denominator * (x - shares[j][2*k])
          denominator = modulo(denominator, primeNumber)
        }
      }

      inversed = modInverse(denominator, primeNumber)

      secret = secret + y*(numerator * inversed)
      secret = modulo(secret, primeNumber)

    }
    
    buffer[k] = secret

  }
  
  return buffer

}

const shares = create('yei예이;', 5, 10)
console.log(combine(shares.slice(1,6)).toString())
