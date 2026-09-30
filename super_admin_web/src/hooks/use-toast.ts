export function useToast() {
  return {
    toast: (props: any) => {
      console.log('Toast triggered:', props);
    }
  };
}
