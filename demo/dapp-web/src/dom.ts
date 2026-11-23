/** Returns the element with `id`, failing loudly if the page doesn't have it or it has another type. */
export function requireElement<T extends HTMLElement>(id: string, type: { new (): T; prototype: T }): T {
  const element = document.getElementById(id);
  if (!(element instanceof type)) {
    throw new Error(`#${id} is missing from index.html or is not a ${type.name}`);
  }
  return element;
}
